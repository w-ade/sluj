/// Decides which processes count as "the app": the app itself, the dev
/// tooling that launched it from its project folder (a vite server, the
/// Tauri CLI), and the helpers macOS runs on its behalf (WebKit).
public enum AppGroup {
    /// Walking up the launch chain stops at these, so a terminal session
    /// (and everything else running in it) never joins the group.
    static let shells: Set<String> = ["zsh", "bash", "sh", "fish", "nu", "dash", "login", "tmux", "screen"]

    /// Returns the target first, then the rest in pid order.
    public static func members(
        of target: Int32,
        in table: [Int32: ProcessSnapshot],
        guiApps: Set<Int32>,
        projectRoot: String?,
        workingDirectory: (Int32) -> String?
    ) -> [Int32] {
        guard let app = table[target] else { return [] }

        var children: [Int32: [Int32]] = [:]
        for process in table.values {
            children[process.parentPid, default: []].append(process.pid)
        }

        var members = Set<Int32>()
        func addTree(_ pid: Int32) {
            guard members.insert(pid).inserted else { return }
            for child in children[pid] ?? [] { addTree(child) }
        }

        addTree(launcher(of: app, in: table, projectRoot: projectRoot, workingDirectory: workingDirectory))
        for helper in helpers(of: app, in: table, guiApps: guiApps) {
            addTree(helper)
        }

        return [target] + members.subtracting([target]).sorted()
    }

    /// The highest ancestor that is still dev tooling running inside the
    /// project folder. For an app opened normally this is the app itself.
    static func launcher(
        of app: ProcessSnapshot,
        in table: [Int32: ProcessSnapshot],
        projectRoot: String?,
        workingDirectory: (Int32) -> String?
    ) -> Int32 {
        guard let projectRoot else { return app.pid }
        var top = app.pid
        var parentPid = app.parentPid
        while parentPid > 1,
              let parent = table[parentPid],
              !shells.contains(parent.name),
              let directory = workingDirectory(parentPid),
              ProjectRoot.contains(directory, root: projectRoot) {
            top = parentPid
            parentPid = parent.parentPid
        }
        return top
    }

    static func helpers(of app: ProcessSnapshot, in table: [Int32: ProcessSnapshot], guiApps: Set<Int32>) -> [Int32] {
        // Opened normally: macOS credits the helpers to the app directly.
        if app.responsiblePid == app.pid {
            return table.values
                .filter { $0.pid != app.pid && $0.responsiblePid == app.pid }
                .map(\.pid)
        }

        // Launched from a terminal: the helpers are credited to the terminal
        // instead, alongside everything else it runs. Each WebKit helper goes
        // to whichever app under that terminal started most recently before
        // it. Only WebKit: other XPC services under a terminal (SourceKit,
        // audio) usually belong to the terminal's other tools.
        let owner = app.responsiblePid
        let isWebKitHelper = { (process: ProcessSnapshot) in
            process.path.contains("/WebKit.framework/") && process.path.contains("/XPCServices/")
        }
        let siblingApps = table.values
            .filter { $0.responsiblePid == owner && (guiApps.contains($0.pid) || $0.pid == app.pid) && !isWebKitHelper($0) }
            .sorted { $0.startTime < $1.startTime }

        return table.values
            .filter { process in
                process.responsiblePid == owner
                    && process.parentPid == 1
                    && isWebKitHelper(process)
                    && process.startTime >= app.startTime
                    && siblingApps.last(where: { $0.startTime <= process.startTime })?.pid == app.pid
            }
            .map(\.pid)
    }
}
