import AppKit
import Observation
import SLUJCore

struct ProcessRow: Identifiable {
    let id: Int32
    let name: String
    let isMain: Bool
    let reading: Reading
}

enum Paths {
    static let developer = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Developer").path
}

/// Watches one app. Samples once a second while the window is visible and
/// does nothing at all otherwise.
@MainActor @Observable
final class Monitor {
    private(set) var target: NSRunningApplication?
    private(set) var processes: [ProcessRow] = []
    private(set) var total: Reading = .zero
    private(set) var status: Status = .fine
    /// False until two samples exist, since CPU, energy and GPU are rates.
    private(set) var hasRates = false
    /// Name of the last watched app if it quit while being watched.
    private(set) var lastQuit: String?

    var isVisible = true {
        didSet { if isVisible != oldValue { restart() } }
    }

    @ObservationIgnored private var sampler = Sampler()
    @ObservationIgnored private var tracker = StatusTracker()
    @ObservationIgnored private var names: [String: String] = [:]
    @ObservationIgnored private var loop: Task<Void, Never>?

    func watch(_ app: NSRunningApplication) {
        target = app
        lastQuit = nil
        names = [:]
        restart()
    }

    func stopWatching() {
        target = nil
        restart()
    }

    private func restart() {
        loop?.cancel()
        loop = nil
        sampler.reset()
        tracker.reset()
        processes = []
        total = .zero
        status = .fine
        hasRates = false
        guard target != nil, isVisible else { return }

        loop = Task { [weak self] in
            while !Task.isCancelled {
                await self?.tick()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func tick() async {
        guard let app = target else { return }
        if app.isTerminated {
            lastQuit = app.localizedName
            stopWatching()
            return
        }

        let pid = app.processIdentifier
        // Only Dock apps: WebKit helpers and command-line tools also appear in
        // runningApplications, and would compete with the app for its helpers.
        let guiApps = Set(NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }.map(\.processIdentifier))
        let projectRoot = app.executableURL.flatMap {
            ProjectRoot.root(forExecutable: $0.path, developerDirectory: Paths.developer)
        }

        let (table, members, time) = await Task.detached(priority: .utility) {
            let table = ProcessTable.snapshot()
            let members = AppGroup.members(
                of: pid, in: table, guiApps: guiApps, projectRoot: projectRoot,
                workingDirectory: ProcessTable.workingDirectory(of:)
            )
            return (table, members, ProcessInfo.processInfo.systemUptime)
        }.value
        guard !Task.isCancelled, target?.processIdentifier == pid else { return }

        hasRates = sampler.hasBaseline
        let readings = sampler.sample(table, members: members, at: time)
        total = readings.reduce(.zero) { $0 + $1.reading }
        status = tracker.update(total, at: time)
        processes = readings
            .map { ProcessRow(id: $0.id, name: name(for: $0.snapshot, app: app), isMain: $0.id == pid, reading: $0.reading) }
            // A stable order, so rows don't jump around every second.
            .sorted { ($0.isMain ? 0 : 1, $0.name, $0.id) < ($1.isMain ? 0 : 1, $1.name, $1.id) }
    }

    private func name(for process: ProcessSnapshot, app: NSRunningApplication) -> String {
        if process.pid == app.processIdentifier { return app.localizedName ?? process.name }
        let key = "\(process.pid)-\(process.startTime)"
        if let cached = names[key] { return cached }
        let arguments = ProcessName.needsArguments(process.name) ? ProcessTable.arguments(of: process.pid) : []
        let name = ProcessName.display(name: process.name, arguments: arguments)
        names[key] = name
        return name
    }
}
