import Foundation

/// One measured, classified unit of developer storage.
///
/// An entry is a directory (usually) that SLUJ measured and reasoned about.
/// It carries its own justification: `reason`, `evidence`, and — when the
/// material is regenerable — a `rebuildRecipe`.
public struct ScanEntry: Identifiable, Sendable, Hashable {
    public let id: UUID

    public let path: URL
    public let name: String
    public let sizeBytes: Int64

    /// The project this storage belongs to, when SLUJ can attribute it.
    public let projectName: String?
    /// The tool that produced or owns this storage, when known (npm, Xcode, Docker…).
    public let toolName: String?

    public let classification: StorageClassification
    public let confidence: ClassificationConfidence

    /// One sentence explaining the classification, in the user's terms.
    public let reason: String
    /// Concrete artifacts SLUJ observed, e.g. `package.json`, `pnpm-lock.yaml`.
    public let evidence: [String]
    /// The command that regenerates this storage, when one exists.
    public let rebuildRecipe: String?

    /// Bytes SLUJ is willing to claim are recoverable.
    ///
    /// Clamped at initialization: `keep` and `review` are always 0, and no
    /// entry may claim more than its own size. This invariant is enforced
    /// here so no call site can bypass it.
    public let reclaimableBytes: Int64

    public init(
        id: UUID = UUID(),
        path: URL,
        name: String? = nil,
        sizeBytes: Int64,
        projectName: String? = nil,
        toolName: String? = nil,
        classification: StorageClassification,
        confidence: ClassificationConfidence,
        reason: String,
        evidence: [String] = [],
        rebuildRecipe: String? = nil,
        reclaimableBytes: Int64? = nil
    ) {
        self.id = id
        self.path = path
        self.name = name ?? path.lastPathComponent
        self.sizeBytes = max(0, sizeBytes)
        self.projectName = projectName
        self.toolName = toolName
        self.classification = classification
        self.confidence = confidence
        self.reason = reason
        self.evidence = evidence
        self.rebuildRecipe = rebuildRecipe

        if classification.canContributeReclaimableBytes {
            let claimed = reclaimableBytes ?? max(0, sizeBytes)
            self.reclaimableBytes = min(max(0, claimed), self.sizeBytes)
        } else {
            self.reclaimableBytes = 0
        }
    }

    /// Whether SLUJ is explicitly withholding judgement on this storage.
    public var needsReview: Bool { classification == .review }
}
