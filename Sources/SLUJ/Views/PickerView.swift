import AppKit
import SwiftUI
import SLUJCore

/// Choose which app to watch. Apps built from ~/Developer, and any app
/// starred by hand, come first.
struct PickerView: View {
    let monitor: Monitor
    @Binding var pinned: Bool
    /// Newline-separated app keys (see `key(for:)`).
    @AppStorage("starredApps") private var starredStorage = ""
    @State private var apps: [NSRunningApplication] = []

    private var starred: Set<String> {
        Set(starredStorage.split(separator: "\n").map(String.init))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Pick an app to watch").font(.slujTitle)
                Spacer()
                PinButton(pinned: $pinned)
            }
            .padding(.horizontal, Dimensions.padding)
            .frame(height: 40)

            if let quit = monitor.lastQuit {
                Text("\(quit) quit.")
                    .font(.slujSmall)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Dimensions.padding)
                    .padding(.bottom, 8)
            }

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    let (mine, others) = groups
                    section("Mine", mine, empty: "Apps built in ~/Developer show up here. Star any other app to add it.")
                    section("Everything else", others, empty: nil)
                }
                .padding(.vertical, 6)
            }
        }
        .onAppear(perform: reload)
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)) { _ in reload() }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didTerminateApplicationNotification)) { _ in reload() }
    }

    @ViewBuilder
    private func section(_ title: String, _ apps: [NSRunningApplication], empty: String?) -> some View {
        Text(title.uppercased())
            .font(.slujSectionLabel)
            .foregroundStyle(.secondary)
            .padding(.horizontal, Dimensions.padding)
            .padding(.top, 10)
            .padding(.bottom, 4)
        if apps.isEmpty, let empty {
            Text(empty)
                .font(.slujSmall)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, Dimensions.padding)
                .padding(.bottom, 4)
        }
        ForEach(apps, id: \.processIdentifier) { app in
            AppRow(
                app: app,
                isDeveloperApp: isDeveloperApp(app),
                isStarred: starred.contains(key(for: app)),
                onSelect: { monitor.watch(app) },
                onToggleStar: { toggleStar(app) }
            )
        }
    }

    private var groups: (mine: [NSRunningApplication], others: [NSRunningApplication]) {
        let mine = apps.filter { isDeveloperApp($0) || starred.contains(key(for: $0)) }
        let others = apps.filter { !mine.contains($0) }
        return (mine, others)
    }

    private func reload() {
        let me = ProcessInfo.processInfo.processIdentifier
        apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.processIdentifier != me }
            .sorted { ($0.localizedName ?? "").localizedCaseInsensitiveCompare($1.localizedName ?? "") == .orderedAscending }
    }

    private func isDeveloperApp(_ app: NSRunningApplication) -> Bool {
        guard let path = app.executableURL?.path else { return false }
        return ProjectRoot.root(forExecutable: path, developerDirectory: Paths.developer) != nil
    }

    private func key(for app: NSRunningApplication) -> String {
        app.bundleIdentifier ?? app.executableURL?.path ?? app.localizedName ?? "\(app.processIdentifier)"
    }

    private func toggleStar(_ app: NSRunningApplication) {
        var keys = starred
        let key = key(for: app)
        if keys.contains(key) { keys.remove(key) } else { keys.insert(key) }
        starredStorage = keys.sorted().joined(separator: "\n")
    }
}

private struct AppRow: View {
    let app: NSRunningApplication
    let isDeveloperApp: Bool
    let isStarred: Bool
    let onSelect: () -> Void
    let onToggleStar: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 8) {
            if let icon = app.icon {
                Image(nsImage: icon).resizable().frame(width: 16, height: 16)
            }
            Text(app.localizedName ?? "Unknown")
                .font(.slujBody)
                .lineLimit(1)
            Spacer()
            star
        }
        .padding(.horizontal, Dimensions.padding)
        .frame(height: 26)
        .background(hovering ? Color.primary.opacity(0.06) : .clear)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering = $0 }
    }

    @ViewBuilder
    private var star: some View {
        if isDeveloperApp {
            Image(systemName: "star.fill")
                .foregroundStyle(.tertiary)
                .help("Built in ~/Developer")
        } else {
            Button(action: onToggleStar) {
                Image(systemName: isStarred ? "star.fill" : "star")
                    .foregroundStyle(isStarred ? .primary : .tertiary)
                    .opacity(isStarred || hovering ? 1 : 0)
            }
            .buttonStyle(.plain)
            .help(isStarred ? "Remove from Mine" : "Add to Mine")
        }
    }
}
