import Foundation

/// A single named piece of classification knowledge.
///
/// Rules are pure descriptions — they carry no filesystem access and perform
/// no side effects. A future scanner matches observed directories against
/// these and produces `ScanEntry` values with the rule's justification
/// attached, so every classification the UI shows can be traced to a rule.
public struct ClassificationRule: Sendable, Identifiable, Hashable {
    public var id: String { name }

    /// The directory name this rule recognises, e.g. `node_modules`.
    public let name: String
    public let toolName: String?
    public let classification: StorageClassification
    public let confidence: ClassificationConfidence
    public let reason: String
    /// Sibling files whose presence supports the classification.
    public let expectedEvidence: [String]
    public let rebuildRecipe: String?

    public init(
        name: String,
        toolName: String? = nil,
        classification: StorageClassification,
        confidence: ClassificationConfidence,
        reason: String,
        expectedEvidence: [String] = [],
        rebuildRecipe: String? = nil
    ) {
        self.name = name
        self.toolName = toolName
        self.classification = classification
        self.confidence = confidence
        self.reason = reason
        self.expectedEvidence = expectedEvidence
        self.rebuildRecipe = rebuildRecipe
    }
}

/// The starter rule set. Intentionally short — SLUJ would rather leave
/// storage in REVIEW than guess, so unknown directories match nothing.
public enum ClassificationRules {
    public static let all: [ClassificationRule] = [
        ClassificationRule(
            name: "node_modules",
            toolName: "npm",
            classification: .rebuildable,
            confidence: .high,
            reason: "Dependency directory generated from package manifests.",
            expectedEvidence: ["package.json", "pnpm-lock.yaml"],
            rebuildRecipe: "pnpm install"
        ),
        ClassificationRule(
            name: ".next",
            toolName: "Next.js",
            classification: .rebuildable,
            confidence: .high,
            reason: "Build output produced by the framework compiler.",
            expectedEvidence: ["next.config.js", "package.json"],
            rebuildRecipe: "pnpm build"
        ),
        ClassificationRule(
            name: ".turbo",
            toolName: "Turborepo",
            classification: .cleanable,
            confidence: .high,
            reason: "Task cache. Removing it costs only a slower next build.",
            expectedEvidence: ["turbo.json"],
            rebuildRecipe: "Regenerated automatically on the next task run."
        ),
        ClassificationRule(
            name: "DerivedData",
            toolName: "Xcode",
            classification: .cleanable,
            confidence: .high,
            reason: "Xcode intermediate build products and indexes.",
            expectedEvidence: ["Build/", "Index.noindex/"],
            rebuildRecipe: "Rebuilt by Xcode on the next build."
        ),
        ClassificationRule(
            name: ".build",
            toolName: "SwiftPM",
            classification: .rebuildable,
            confidence: .high,
            reason: "SwiftPM build artifacts compiled from package sources.",
            expectedEvidence: ["Package.swift", "Package.resolved"],
            rebuildRecipe: "swift build"
        ),
    ]

    public static func rule(named name: String) -> ClassificationRule? {
        all.first { $0.name == name }
    }
}
