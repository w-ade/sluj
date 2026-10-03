import AppKit
import SwiftUI

/// The same half-circle toggle used by Portbrowser: a clockwise half-turn
/// with a little overshoot on every click, plus a subtle pressed dip.
struct ThemeToggle: View {
    @AppStorage("theme") private var theme = "system"
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var turns = 0
    @State private var hovering = false

    private var nextTheme: String { colorScheme == .dark ? "light" : "dark" }
    private var label: String { "Switch to \(nextTheme) mode" }

    var body: some View {
        Button {
            let next = nextTheme
            withAnimation(reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.25)) {
                turns += 1
            }
            theme = next
            AppAppearance.apply(next)
        } label: {
            ZStack {
                Circle()
                    .inset(by: 14 * 1.5 / 16)
                    .stroke(lineWidth: 14 * 1.25 / 16)
                FilledHalfCircle()
            }
            .frame(width: 14, height: 14)
            .rotationEffect(.degrees(Double(turns) * 180))
            .foregroundStyle(hovering ? Theme.ink : Theme.chevron)
            .frame(width: 18, height: 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(ThemeToggleStyle(reduceMotion: reduceMotion))
        .onHover { hovering = $0 }
        .help(label)
        .accessibilityLabel(label)
        .accessibilityValue(colorScheme == .dark ? "Dark" : "Light")
    }
}

private struct FilledHalfCircle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) * 6.5 / 16,
            startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

private struct ThemeToggleStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.9 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

@MainActor
enum AppAppearance {
    static func apply(_ theme: String) {
        switch theme {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        default: NSApp.appearance = nil
        }
    }

    /// Apply before the first window is drawn. Screenshot overrides are
    /// launch-only; they don't replace the user's saved preference.
    static func restore() {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--appearance"), index + 1 < arguments.count {
            apply(arguments[index + 1])
        } else {
            apply(UserDefaults.standard.string(forKey: "theme") ?? "system")
        }
    }
}
