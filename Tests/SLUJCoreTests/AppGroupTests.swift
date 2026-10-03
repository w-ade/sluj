import Testing
@testable import SLUJCore

private let root = "/Users/me/Developer/Tools/bench"
private let webkit = "/System/Library/Frameworks/WebKit.framework/Versions/A/XPCServices"

private func process(_ pid: Int32, parent: Int32, responsible: Int32, _ name: String, path: String? = nil, start: Double) -> ProcessSnapshot {
    ProcessSnapshot(pid: pid, parentPid: parent, responsiblePid: responsible, name: name, path: path ?? "/bin/\(name)", startTime: start)
}

private func table(_ processes: [ProcessSnapshot]) -> [Int32: ProcessSnapshot] {
    Dictionary(uniqueKeysWithValues: processes.map { ($0.pid, $0) })
}

/// Bench in Tauri dev mode, launched from a Ghostty shell, the way
/// `npm run app` runs it.
private let devSession: [Int32: ProcessSnapshot] = table([
    process(10, parent: 1, responsible: 10, "ghostty", start: 0),
    process(11, parent: 10, responsible: 10, "zsh", start: 1),
    process(12, parent: 11, responsible: 10, "node", path: "/opt/homebrew/bin/node", start: 100),  // npm run app
    process(13, parent: 12, responsible: 10, "node", path: "/opt/homebrew/bin/node", start: 101),  // tauri dev
    process(14, parent: 13, responsible: 10, "node", path: "/opt/homebrew/bin/node", start: 102),  // vite
    process(15, parent: 13, responsible: 10, "cargo", start: 103),
    process(16, parent: 15, responsible: 10, "bench", path: "\(root)/src-tauri/target/debug/bench", start: 110),
    process(17, parent: 1, responsible: 10, "com.apple.WebKit.WebContent", path: "\(webkit)/WebContent", start: 111),
    process(18, parent: 1, responsible: 10, "com.apple.WebKit.GPU", path: "\(webkit)/GPU", start: 111),
    // Another shell in the same terminal, sitting in the project folder.
    process(20, parent: 10, responsible: 10, "zsh", start: 2),
    process(21, parent: 20, responsible: 10, "node", path: "/opt/homebrew/bin/node", start: 50),
])

private let devDirectories: [Int32: String] = [11: root, 12: root, 13: root, 14: root, 15: "\(root)/src-tauri", 20: root, 21: root]

@Test func devModeIncludesLauncherDevServerAndWebKitHelpers() {
    let members = AppGroup.members(
        of: 16, in: devSession, guiApps: [10, 16], projectRoot: root,
        workingDirectory: { devDirectories[$0] }
    )
    #expect(members == [16, 12, 13, 14, 15, 17, 18])
}

@Test func helpersListedAsAppsDontClaimThemselves() {
    // NSWorkspace lists WebKit helpers as running applications too.
    let members = AppGroup.members(
        of: 16, in: devSession, guiApps: [10, 16, 17, 18], projectRoot: root,
        workingDirectory: { devDirectories[$0] }
    )
    #expect(members.contains(17))
    #expect(members.contains(18))
}

@Test func walkingUpStopsAtTheShell() {
    let members = AppGroup.members(
        of: 16, in: devSession, guiApps: [10, 16], projectRoot: root,
        workingDirectory: { devDirectories[$0] }
    )
    #expect(!members.contains(11))
    #expect(!members.contains(21), "other processes in the project folder aren't part of the app")
}

@Test func withoutAProjectOnlyTheAppAndItsHelpersCount() {
    let members = AppGroup.members(
        of: 16, in: devSession, guiApps: [10, 16], projectRoot: nil,
        workingDirectory: { devDirectories[$0] }
    )
    #expect(members == [16, 17, 18])
}

@Test func terminalHelpersGoToTheMostRecentlyStartedApp() {
    var session = devSession
    // A second app launched from the same terminal after Bench, with its own WebContent.
    session[30] = process(30, parent: 11, responsible: 10, "other", start: 200)
    session[31] = process(31, parent: 1, responsible: 10, "com.apple.WebKit.WebContent", path: "\(webkit)/WebContent", start: 201)
    // A helper the terminal started before Bench existed.
    session[32] = process(32, parent: 1, responsible: 10, "com.apple.WebKit.WebContent", path: "\(webkit)/WebContent", start: 5)
    // A non-WebKit XPC service an editor in the same terminal started after Bench.
    session[33] = process(33, parent: 1, responsible: 10, "SourceKitService",
                          path: "/Applications/Xcode.app/Contents/SharedFrameworks/sourcekitd.framework/XPCServices/SourceKitService.xpc/SourceKitService", start: 150)

    let members = AppGroup.members(
        of: 16, in: session, guiApps: [10, 16, 30], projectRoot: root,
        workingDirectory: { devDirectories[$0] }
    )
    #expect(members.contains(17))
    #expect(!members.contains(31))
    #expect(!members.contains(32))
    #expect(!members.contains(33))
}

@Test func appOpenedNormallyOwnsItsHelpers() {
    let session = table([
        process(40, parent: 1, responsible: 40, "Ment", path: "/Applications/Ment.app/Contents/MacOS/Ment", start: 10),
        process(41, parent: 1, responsible: 40, "com.apple.WebKit.WebContent", path: "\(webkit)/WebContent", start: 11),
        process(42, parent: 40, responsible: 40, "helper", start: 12),
        process(50, parent: 1, responsible: 50, "Safari", start: 5),
        process(51, parent: 1, responsible: 50, "com.apple.WebKit.WebContent", path: "\(webkit)/WebContent", start: 13),
    ])
    let members = AppGroup.members(of: 40, in: session, guiApps: [40, 50], projectRoot: nil, workingDirectory: { _ in nil })
    #expect(members == [40, 41, 42])
}

@Test func unknownTargetIsEmpty() {
    #expect(AppGroup.members(of: 999, in: devSession, guiApps: [], projectRoot: nil, workingDirectory: { _ in nil }).isEmpty)
}

@Test func projectRootFromExecutablePath() {
    let developer = "/Users/me/Developer"
    #expect(ProjectRoot.root(forExecutable: "\(root)/src-tauri/target/debug/bench", developerDirectory: developer) == root)
    #expect(ProjectRoot.root(forExecutable: "/Users/me/Developer/Tools/bench", developerDirectory: developer) == nil)
    #expect(ProjectRoot.root(forExecutable: "/Applications/Ment.app/Contents/MacOS/Ment", developerDirectory: developer) == nil)
    #expect(ProjectRoot.contains("\(root)/src-tauri", root: root))
    #expect(!ProjectRoot.contains("\(root)-old", root: root))
}
