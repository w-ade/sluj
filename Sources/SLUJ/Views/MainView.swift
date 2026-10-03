import AppKit
import SwiftUI

struct MainView: View {
    let monitor: Monitor
    @AppStorage("pinned") private var pinned = false

    var body: some View {
        Group {
            if let app = monitor.target {
                MonitorView(monitor: monitor, app: app, pinned: $pinned)
            } else {
                PickerView(monitor: monitor, pinned: $pinned)
            }
        }
        .background(WindowObserver(pinned: pinned) { monitor.isVisible = $0 })
        .onAppear(perform: watchFromArguments)
    }

    /// `--watch <app name>` opens straight into that app, for design
    /// iteration and screenshots.
    private func watchFromArguments() {
        let arguments = ProcessInfo.processInfo.arguments
        guard monitor.target == nil,
              let index = arguments.firstIndex(of: "--watch"), index + 1 < arguments.count,
              let app = NSWorkspace.shared.runningApplications.first(where: {
                  $0.localizedName?.localizedCaseInsensitiveCompare(arguments[index + 1]) == .orderedSame
              })
        else { return }
        monitor.watch(app)
    }
}

struct PinButton: View {
    @Binding var pinned: Bool

    var body: some View {
        Button {
            pinned.toggle()
        } label: {
            Image(systemName: pinned ? "pin.fill" : "pin")
                .foregroundStyle(pinned ? .primary : .secondary)
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(pinned ? "Stop floating above other apps" : "Float above other apps")
    }
}

/// Reaches the hosting NSWindow to float it when pinned and to report
/// whether any of it is on screen, so sampling can pause when it isn't.
struct WindowObserver: NSViewRepresentable {
    let pinned: Bool
    let onVisibilityChange: (Bool) -> Void

    func makeNSView(context: Context) -> ObserverView {
        let view = ObserverView()
        view.onVisibilityChange = onVisibilityChange
        view.pinned = pinned
        return view
    }

    func updateNSView(_ view: ObserverView, context: Context) {
        view.onVisibilityChange = onVisibilityChange
        view.pinned = pinned
    }

    final class ObserverView: NSView {
        var onVisibilityChange: ((Bool) -> Void)?
        var pinned = false {
            didSet { applyLevel() }
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            NotificationCenter.default.removeObserver(self)
            guard let window else { return }
            applyLevel()
            NotificationCenter.default.addObserver(
                self, selector: #selector(occlusionChanged),
                name: NSWindow.didChangeOcclusionStateNotification, object: window
            )
            occlusionChanged()
        }

        @objc private func occlusionChanged() {
            onVisibilityChange?(window?.occlusionState.contains(.visible) ?? false)
        }

        private func applyLevel() {
            window?.level = pinned ? .floating : .normal
        }
    }
}
