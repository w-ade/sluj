import AppKit
import SwiftUI

@main
struct SLUJApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var monitor = Monitor()

    var body: some Scene {
        Window("sluj", id: "main") {
            MainView(monitor: monitor)
                // Keep the complete window at the designed card height while
                // allowing macOS to reserve its standard title bar.
                .frame(width: Dimensions.windowWidth, height: Dimensions.windowHeight - Dimensions.titlebarInset)
        }
        .windowResizability(.contentSize)
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
        AppAppearance.restore()
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
