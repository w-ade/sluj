import SwiftUI
import SLUJCore

/// A deliberately small visual vocabulary.
///
/// SLUJ is monochrome by default: classification is carried by fill weight
/// and a small badge, not by colour. Only REVIEW gets a hint of hue, and only
/// because "SLUJ is withholding judgement here" is the one thing the user
/// must not misread.
enum Metric {
    static let windowPadding: CGFloat = 20
    static let sectionGap: CGFloat = 0
    static let controlRadius: CGFloat = 5
    static let cellRadius: CGFloat = 3
    static let inspectorWidth: CGFloat = 288
    static let rowGap: CGFloat = 6
}

extension StorageClassification {
    /// Treemap fill. Weight increases with how confidently disposable the
    /// storage is, so the reclaimable mass reads as one tonal block.
    var fill: Color {
        switch self {
        case .keep: Color.primary.opacity(0.055)
        case .rebuildable: Color.primary.opacity(0.16)
        case .cleanable: Color.primary.opacity(0.28)
        case .review: Color.primary.opacity(0.10)
        }
    }

    var stroke: Color {
        switch self {
        case .review: Color.primary.opacity(0.45)
        default: Color.primary.opacity(0.12)
        }
    }

    /// REVIEW is drawn with a dashed edge — the visual equivalent of
    /// "SLUJ does not know."
    var usesDashedStroke: Bool { self == .review }

    var badgeForeground: Color {
        switch self {
        case .keep: Color.primary.opacity(0.55)
        case .rebuildable, .cleanable: Color.primary.opacity(0.75)
        case .review: Color.primary.opacity(0.75)
        }
    }

    var badgeBackground: Color {
        switch self {
        case .review: Color.primary.opacity(0.06)
        default: Color.primary.opacity(0.06)
        }
    }

    /// One line describing what this classification means, for the filter bar.
    var help: String {
        switch self {
        case .keep: "Authored work or source-of-truth material."
        case .rebuildable: "Generated material that can be recreated from source."
        case .cleanable: "Known disposable developer residue."
        case .review: "Not enough evidence to classify safely. Never counted as reclaimable."
        }
    }
}

extension Font {
    static let slujStatValue = Font.system(size: 22, weight: .regular).monospacedDigit()
    static let slujStatLabel = Font.system(size: 11, weight: .regular)
    static let slujSectionLabel = Font.system(size: 10, weight: .semibold)
    static let slujBody = Font.system(size: 12)
    static let slujMono = Font.system(size: 11, design: .monospaced)
}
