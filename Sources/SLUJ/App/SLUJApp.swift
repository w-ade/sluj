import AppKit
import SwiftUI

@main
struct SLUJApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Window("SLUJ", id: "main") {
            MainView()
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

/// SLUJ builds as a plain SwiftPM executable, so it has no bundle to declare
/// its activation policy. Promoting it to `.regular` here gives it a Dock
/// icon, a menu bar, and focus when launched from the terminal.
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Set before any window exists. Promoting the policy after the window is
    /// created leaves its content view sized against the old titlebar metrics,
    /// which clips the bottom of the layout.
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        // The app draws its own header row, so the titlebar repeats the name.
        for window in NSApp.windows {
            window.titleVisibility = .hidden
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
