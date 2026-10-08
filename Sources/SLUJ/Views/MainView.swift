import AppKit
import SwiftUI

/// The window content below macOS's standard title bar.
struct MainView: View {
    let monitor: Monitor
    @AppStorage("pinned") private var pinned = false

    var body: some View {
        VStack(alignment: .leading, spacing: Dimensions.sectionGap) {
            if let app = monitor.target {
                MonitorView(monitor: monitor, app: app, pinned: $pinned)
            } else {
                PickerView(monitor: monitor)
            }
        }
        .padding(Dimensions.padding)
        .padding(.top, Dimensions.sectionGap)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.background)
        .ignoresSafeArea()
        .background(WindowObserver(pinned: pinned) { monitor.isVisible = $0 })
        .onAppear(perform: watchFromArguments)
    }

    /// `--watch <app name>` opens straight into that app, and
    /// `--appearance light|dark` forces the theme, for design iteration and
    /// screenshots.
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
            Image(nsImage: PrimerPinIcon.image)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(pinned ? Theme.ink : Theme.chevron)
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(pinned ? "Stop floating above other apps" : "Float above other apps")
    }
}

/// Primer Octicons' 16-point PinIcon, embedded as vector SVG so the native
/// app uses the same glyph as `@primer/octicons-react`.
private enum PrimerPinIcon {
    static let image: NSImage = {
        let svg = #"""
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16"><path d="m11.294.984 3.722 3.722a1.75 1.75 0 0 1-.504 2.826l-1.327.613a3.089 3.089 0 0 0-1.707 2.084l-.584 2.454c-.317 1.332-1.972 1.8-2.94.832L5.75 11.311 1.78 15.28a.749.749 0 1 1-1.06-1.06l3.969-3.97-2.204-2.204c-.968-.968-.5-2.623.832-2.94l2.454-.584a3.08 3.08 0 0 0 2.084-1.707l.613-1.327a1.75 1.75 0 0 1 2.826-.504ZM6.283 9.723l2.732 2.731a.25.25 0 0 0 .42-.119l.584-2.454a4.586 4.586 0 0 1 2.537-3.098l1.328-.613a.25.25 0 0 0 .072-.404l-3.722-3.722a.25.25 0 0 0-.404.072l-.613 1.328a4.584 4.584 0 0 1-3.098 2.537l-2.454.584a.25.25 0 0 0-.119.42l2.731 2.732Z"/></svg>
        """#
        let image = NSImage(data: Data(svg.utf8)) ?? NSImage(size: NSSize(width: 16, height: 16))
        image.isTemplate = true
        return image
    }()
}

/// Reaches the hosting NSWindow to float it when pinned and report whether
/// any of it is on screen so sampling can pause.
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
            didSet { window?.level = pinned ? .floating : .normal }
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            NotificationCenter.default.removeObserver(self)
            guard let window else { return }

            window.level = pinned ? .floating : .normal
            window.toolbar = nil
            window.styleMask.insert(.fullSizeContentView)
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true

            let center = NotificationCenter.default
            center.addObserver(self, selector: #selector(occlusionChanged),
                               name: NSWindow.didChangeOcclusionStateNotification, object: window)
            occlusionChanged()
        }

        @objc private func occlusionChanged() {
            onVisibilityChange?(window?.occlusionState.contains(.visible) ?? false)
        }

    }
}
