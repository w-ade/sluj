import Foundation

/// The aggregate result of a scan: every measured entry plus the totals
/// derived from them.
///
/// Totals are computed, never stored independently, so the reclaimable
/// figure can never drift away from the entries that justify it.
public struct ScanReport: Sendable, Identifiable {
    public let id: UUID
    public let roots: [URL]
    public let entries: [ScanEntry]

    public init(id: UUID = UUID(), roots: [URL], entries: [ScanEntry]) {
        self.id = id
        self.roots = roots
        self.entries = entries
    }

    /// Everything SLUJ measured, regardless of classification.
    public var totalBytes: Int64 {
        entries.reduce(0) { $0 + $1.sizeBytes }
    }

    /// Storage SLUJ is willing to claim is recoverable.
    ///
    /// KEEP and REVIEW contribute nothing — enforced at `ScanEntry` init.
    public var reclaimableBytes: Int64 {
        entries.reduce(0) { $0 + $1.reclaimableBytes }
    }

    /// Storage SLUJ deliberately refuses to judge. Never reclaimable.
    public var reviewBytes: Int64 {
        entries.filter(\.needsReview).reduce(0) { $0 + $1.sizeBytes }
    }

    public var projectCount: Int {
        Set(entries.compactMap(\.projectName)).count
    }

    public func bytes(for classification: StorageClassification) -> Int64 {
        entries
            .filter { $0.classification == classification }
            .reduce(0) { $0 + $1.sizeBytes }
    }

    public func entries(matching classifications: Set<StorageClassification>) -> [ScanEntry] {
        entries.filter { classifications.contains($0.classification) }
    }

    /// Entries grouped by project, largest group first.
    /// Entries with no project attribution are grouped under `fallback`.
    public func grouped(by dimension: GroupingDimension, fallback: String = "Unattributed") -> [ScanGroup] {
        let buckets = Dictionary(grouping: entries) { entry -> String in
            switch dimension {
            case .project: entry.projectName ?? entry.toolName ?? fallback
            case .tool: entry.toolName ?? entry.projectName ?? fallback
            case .reclaimability: entry.classification.label
            }
        }
        return buckets
            .map { ScanGroup(name: $0.key, entries: $0.value.sorted { $0.sizeBytes > $1.sizeBytes }) }
            .sorted { $0.totalBytes > $1.totalBytes }
    }
}

/// The lens the UI is currently viewing the report through.
public enum GroupingDimension: String, Sendable, CaseIterable, Hashable {
    case project
    case tool
    case reclaimability

    public var label: String {
        switch self {
        case .project: "By Project"
        case .tool: "By Type"
        case .reclaimability: "Reclaimability"
        }
    }
}

public struct ScanGroup: Identifiable, Sendable {
    public var id: String { name }
    public let name: String
    public let entries: [ScanEntry]

    public init(name: String, entries: [ScanEntry]) {
        self.name = name
        self.entries = entries
    }

    public var totalBytes: Int64 { entries.reduce(0) { $0 + $1.sizeBytes } }
    public var reclaimableBytes: Int64 { entries.reduce(0) { $0 + $1.reclaimableBytes } }
}
