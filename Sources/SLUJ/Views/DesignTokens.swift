import AppKit
import SwiftUI
import SLUJCore

/// Sizes from the SLJ-AE5XA Figma frame (docs/design/SLJ-AE5XA.png).
enum Dimensions {
    static let windowWidth: CGFloat = 500
    static let windowHeight: CGFloat = 313
    /// Height SwiftUI reserves for a hidden titlebar (macOS 26).
    static let titlebarInset: CGFloat = 28
    static let padding: CGFloat = 24
    /// The traffic lights' row: 12 pt circles, 8 pt apart.
    static let lightsRow: CGFloat = 12
    static let lightSize: CGFloat = 12
    static let lightSpacing: CGFloat = 8
    static let sectionGap: CGFloat = 16
    static let headerHeight: CGFloat = 32
    static let statHeight: CGFloat = 36
    static let rangeHeight: CGFloat = 20
    static let barHeight: CGFloat = 42
    static let barGap: CGFloat = 4
    static let barRadius: CGFloat = 3
}

/// Neutrals, light and dark (SLJ-AE5XA / SLJ-V8WP9).
enum Theme {
    static let background = Color(light: 0xFFFFFF, dark: 0x171717)
    static let border = Color(light: 0xE5E5E5, dark: 0x262626)
    static let ink = Color(light: 0x000000, dark: 0xFAFAFA)
    static let muted = Color(light: 0x737373, dark: 0xA1A1A1)
    static let icon = Color(light: 0xB7B7B7, dark: 0x5C5C5C)
    static let chevron = Color(light: 0xA1A1A1, dark: 0x737373)
    static let hover = Color(light: 0xF5F5F5, dark: 0x202020)
}

/// Colour carries meaning only: status, and one colour per process.
enum Palette {
    static let fine = Color(hex: 0x20C76A)
    static let warm = Color(hex: 0xFFD84A)
    static let heavy = Color(hex: 0xF04452)

    /// Process bars, in the order processes first appear (largest first).
    static let series: [Color] = [0x4B73FF, 0x2EC5E8, 0x8B5CF6, 0xE94BFF, 0xFF9F1A, 0xFFD84A, 0x20C76A, 0xF04452].map { Color(hex: $0) }

    static func series(_ slot: Int) -> Color { series[slot % series.count] }

    /// Reserved for recording (roadmap).
    static let recording = Color(hex: 0xFF9F1A)
}

extension Status {
    var color: Color {
        switch self {
        case .fine: Palette.fine
        case .warm: Palette.warm
        case .heavy: Palette.heavy
        }
    }

    var label: String {
        switch self {
        case .fine: "fine"
        case .warm: "warm"
        case .heavy: "too heavy"
        }
    }
}

extension Font {
    /// Inter is bundled into SLUJ.app (scripts/make-app.sh). `swift run`
    /// has no bundle, so it falls back to the system font.
    static func inter(_ size: CGFloat) -> Font { .custom("InterVariable", size: size) }
}

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }

    convenience init(light: UInt32, dark: UInt32) {
        self.init(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? NSColor(hex: dark) : NSColor(hex: light)
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(nsColor: NSColor(hex: hex))
    }

    init(light: UInt32, dark: UInt32) {
        self.init(nsColor: NSColor(light: light, dark: dark))
    }
}
