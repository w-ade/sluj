import SwiftUI
import SLUJCore

enum Dimensions {
    static let windowWidth: CGFloat = 280
    static let windowHeight: CGFloat = 385
    static let padding: CGFloat = 14
    static let rowGap: CGFloat = 10
}

/// Colour carries meaning only: status, and which number is which.
/// Everything else stays monochrome system colour.
enum Palette {
    static let fine = Color(hex: 0x20C76A)
    static let warm = Color(hex: 0xFFD84A)
    static let heavy = Color(hex: 0xF04452)

    static let cpu = Color(hex: 0x4B73FF)
    static let memory = Color(hex: 0x8B5CF6)
    static let energy = Color(hex: 0x2EC5E8)
    static let gpu = Color(hex: 0xE94BFF)

    /// Reserved for recording (roadmap).
    static let recording = Color(hex: 0xFF9F1A)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
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
    static let slujTitle = Font.system(size: 13, weight: .semibold)
    static let slujBody = Font.system(size: 12)
    static let slujSmall = Font.system(size: 11)
    static let slujSectionLabel = Font.system(size: 10, weight: .semibold)
}
