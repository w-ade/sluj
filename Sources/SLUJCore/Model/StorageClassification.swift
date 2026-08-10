import Foundation

/// How SLUJ understands a piece of developer storage.
///
/// The vocabulary is deliberately small. SLUJ prefers being uncertain
/// (`review`) over being dangerously confident.
public enum StorageClassification: String, Sendable, CaseIterable, Codable, Hashable {
    /// Authored work or source-of-truth material.
    case keep
    /// Generated material that can be recreated from source or configuration.
    case rebuildable
    /// Known disposable developer residue, such as tool caches.
    case cleanable
    /// Ambiguous material SLUJ cannot classify safely with the evidence it has.
    case review

    public var label: String {
        switch self {
        case .keep: "KEEP"
        case .rebuildable: "REBUILDABLE"
        case .cleanable: "CLEANABLE"
        case .review: "REVIEW"
        }
    }

    /// Whether storage with this classification is allowed to count toward
    /// the reclaimable total.
    ///
    /// `keep` is work. `review` is unknown. Neither is ever reclaimable.
    public var canContributeReclaimableBytes: Bool {
        switch self {
        case .rebuildable, .cleanable: true
        case .keep, .review: false
        }
    }
}

public enum ClassificationConfidence: String, Sendable, CaseIterable, Codable, Hashable {
    case high
    case medium
    case low

    public var label: String {
        switch self {
        case .high: "High confidence"
        case .medium: "Medium confidence"
        case .low: "Low confidence"
        }
    }
}
