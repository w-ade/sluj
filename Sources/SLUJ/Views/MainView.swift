import AppKit
import SwiftUI

/// The whole window is the card. The top row is left empty for the real
/// traffic lights, which `WindowObserver` moves into it.
struct MainView: View {
    let monitor: Monitor
    @AppStorage("pinned") private var pinned = false

    var body: some View {
        VStack(alignment: .leading, spacing: Dimensions.sectionGap) {
            HStack(spacing: 8) {
                Spacer()
                ThemeToggle()
                PinButton(pinned: $pinned)
            }
            .frame(height: Dimensions.lightsRow)

            if let app = monitor.target {
                MonitorView(monitor: monitor, app: app)
            } else {
                PickerView(monitor: monitor)
            }
        }
        .padding(Dimensions.padding)
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
            Image(systemName: pinned ? "pin.fill" : "pin")
                .font(.system(size: 10))
                .foregroundStyle(pinned ? Theme.ink : Theme.chevron)
                .frame(width: 18, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(pinned ? "Stop floating above other apps" : "Float above other apps")
    }
}

/// Reaches the hosting NSWindow to give it the card look (full-size content,
/// traffic lights inset to the content grid), float it when pinned, and
/// report whether any of it is on screen so sampling can pause.
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
            window.styleMask.insert(.fullSizeContentView)
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
            // Don't set window.backgroundColor: on macOS 26 it hides the
            // traffic lights. The SwiftUI background paints the card instead.

            let center = NotificationCenter.default
            center.addObserver(self, selector: #selector(occlusionChanged),
                               name: NSWindow.didChangeOcclusionStateNotification, object: window)
            // AppKit lays the titlebar out again on these; put the lights back each time.
            for name in [NSWindow.didResizeNotification, NSWindow.didBecomeKeyNotification,
                         NSWindow.didResignKeyNotification, NSWindow.didExitFullScreenNotification] {
                center.addObserver(self, selector: #selector(placeTrafficLights), name: name, object: window)
            }
            placeTrafficLights()
            DispatchQueue.main.async { [weak self] in self?.placeTrafficLights() }
            occlusionChanged()
        }

        @objc private func occlusionChanged() {
            onVisibilityChange?(window?.occlusionState.contains(.visible) ?? false)
        }

        /// Close, minimise and zoom, with their circles' top-left at the
        /// content padding, 8 pt apart. The titlebar is only ~28 pt tall, so
        /// it's stretched first; otherwise the moved buttons would be clipped.
        @objc private func placeTrafficLights() {
            guard let window,
                  let titlebar = window.standardWindowButton(.closeButton)?.superview,
                  let container = titlebar.superview
            else { return }

            let needed = Dimensions.padding * 2 + Dimensions.lightSize
            if container.frame.height < needed {
                container.frame = NSRect(x: 0, y: window.frame.height - needed, width: window.frame.width, height: needed)
                titlebar.frame = container.bounds
            }

            let buttons: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
            for (index, type) in buttons.enumerated() {
                guard let button = window.standardWindowButton(type), let parent = button.superview else { continue }
                let step = Dimensions.lightSize + Dimensions.lightSpacing
                let centerX = Dimensions.padding + Dimensions.lightSize / 2 + CGFloat(index) * step
                let centerFromTop = Dimensions.padding + Dimensions.lightSize / 2
                // Window coordinates have their origin at the bottom left.
                let center = parent.convert(NSPoint(x: centerX, y: window.frame.height - centerFromTop), from: nil)
                button.setFrameOrigin(NSPoint(x: center.x - button.frame.width / 2, y: center.y - button.frame.height / 2))
            }
        }
    }
}
