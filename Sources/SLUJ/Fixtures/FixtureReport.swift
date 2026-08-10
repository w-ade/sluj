import Foundation
import SLUJCore

/// Realistic stand-in data for a developer Mac.
///
/// v0.1 runs the entire UI from this. Nothing here touches the filesystem —
/// the paths are plausible strings, not directories SLUJ visited.
enum FixtureReport {
    static let developerRoot = URL(fileURLWithPath: NSHomeDirectory() + "/Developer")
    static let libraryRoot = URL(fileURLWithPath: NSHomeDirectory() + "/Library")

    static func make() -> ScanReport {
        ScanReport(roots: [developerRoot, libraryRoot], entries: entries)
    }

    private static func gb(_ value: Double) -> Int64 { Int64(value * 1_000_000_000) }
    private static func mb(_ value: Double) -> Int64 { Int64(value * 1_000_000) }

    private static func dev(_ path: String) -> URL {
        developerRoot.appendingPathComponent(path)
    }

    private static func lib(_ path: String) -> URL {
        libraryRoot.appendingPathComponent(path)
    }

    // MARK: - Entries

    static let entries: [ScanEntry] = browserJot + basehull + ridgeline + tidewater
        + palegrove + nightwatch + marrowfield + slujItself + toolStorage

    private static let browserJot: [ScanEntry] = [
        ScanEntry(
            path: dev("browser-jot/src"),
            name: "src",
            sizeBytes: mb(148),
            projectName: "Browser Jot",
            toolName: "TypeScript",
            classification: .keep,
            confidence: .high,
            reason: "Authored application source under version control.",
            evidence: ["tsconfig.json", "tracked by git"]
        ),
        ScanEntry(
            path: dev("browser-jot/public/assets"),
            name: "public/assets",
            sizeBytes: gb(1.9),
            projectName: "Browser Jot",
            toolName: "TypeScript",
            classification: .keep,
            confidence: .high,
            reason: "Original image and video assets with no upstream source.",
            evidence: ["tracked by git", "no generator config found"]
        ),
        ScanEntry(
            path: dev("browser-jot/node_modules"),
            name: "node_modules",
            sizeBytes: gb(8.4),
            projectName: "Browser Jot",
            toolName: "pnpm",
            classification: .rebuildable,
            confidence: .high,
            reason: "Dependency directory generated from package manifests.",
            evidence: ["package.json", "pnpm-lock.yaml"],
            rebuildRecipe: "pnpm install"
        ),
        ScanEntry(
            path: dev("browser-jot/.next"),
            name: ".next",
            sizeBytes: gb(2.1),
            projectName: "Browser Jot",
            toolName: "Next.js",
            classification: .rebuildable,
            confidence: .high,
            reason: "Framework build output compiled from project source.",
            evidence: ["next.config.js", "package.json"],
            rebuildRecipe: "pnpm build"
        ),
    ]

    private static let basehull: [ScanEntry] = [
        ScanEntry(
            path: dev("basehull/source"),
            name: "source",
            sizeBytes: mb(96),
            projectName: "Basehull",
            toolName: "TypeScript",
            classification: .keep,
            confidence: .high,
            reason: "Authored application source under version control.",
            evidence: ["tracked by git"]
        ),
        ScanEntry(
            path: dev("basehull/node_modules"),
            name: "node_modules",
            sizeBytes: gb(6.2),
            projectName: "Basehull",
            toolName: "pnpm",
            classification: .rebuildable,
            confidence: .high,
            reason: "Dependency directory generated from package manifests.",
            evidence: ["package.json", "pnpm-lock.yaml"],
            rebuildRecipe: "pnpm install"
        ),
        ScanEntry(
            path: dev("basehull/.turbo"),
            name: ".turbo",
            sizeBytes: gb(1.4),
            projectName: "Basehull",
            toolName: "Turborepo",
            classification: .cleanable,
            confidence: .high,
            reason: "Task cache. Removing it costs only a slower next build.",
            evidence: ["turbo.json"],
            rebuildRecipe: "Repopulated automatically on the next task run."
        ),
    ]

    private static let ridgeline: [ScanEntry] = [
        ScanEntry(
            path: dev("ridgeline/src"),
            name: "src",
            sizeBytes: mb(41),
            projectName: "Ridgeline",
            toolName: "TypeScript",
            classification: .keep,
            confidence: .high,
            reason: "Authored application source under version control.",
            evidence: ["tracked by git"]
        ),
        ScanEntry(
            path: dev("ridgeline/node_modules"),
            name: "node_modules",
            sizeBytes: gb(3.3),
            projectName: "Ridgeline",
            toolName: "npm",
            classification: .rebuildable,
            confidence: .high,
            reason: "Dependency directory generated from package manifests.",
            evidence: ["package.json", "package-lock.json"],
            rebuildRecipe: "npm install"
        ),
    ]

    private static let tidewater: [ScanEntry] = [
        ScanEntry(
            path: dev("tidewater/src"),
            name: "src",
            sizeBytes: mb(28),
            projectName: "Tidewater",
            toolName: "TypeScript",
            classification: .keep,
            confidence: .high,
            reason: "Authored application source under version control.",
            evidence: ["tracked by git"]
        ),
        ScanEntry(
            path: dev("tidewater/node_modules"),
            name: "node_modules",
            sizeBytes: gb(2.2),
            projectName: "Tidewater",
            toolName: "pnpm",
            classification: .rebuildable,
            confidence: .high,
            reason: "Dependency directory generated from package manifests.",
            evidence: ["package.json", "pnpm-lock.yaml"],
            rebuildRecipe: "pnpm install"
        ),
    ]

    private static let palegrove: [ScanEntry] = [
        ScanEntry(
            path: dev("palegrove/src"),
            name: "src",
            sizeBytes: mb(19),
            projectName: "Palegrove",
            toolName: "Rust",
            classification: .keep,
            confidence: .high,
            reason: "Authored application source under version control.",
            evidence: ["tracked by git"]
        ),
        ScanEntry(
            path: dev("palegrove/target"),
            name: "target",
            sizeBytes: gb(4.6),
            projectName: "Palegrove",
            toolName: "Cargo",
            classification: .rebuildable,
            confidence: .high,
            reason: "Compiler output and dependency builds produced from source.",
            evidence: ["Cargo.toml", "Cargo.lock"],
            rebuildRecipe: "cargo build"
        ),
    ]

    private static let nightwatch: [ScanEntry] = [
        ScanEntry(
            path: dev("nightwatch-api/app"),
            name: "app",
            sizeBytes: mb(34),
            projectName: "Nightwatch API",
            toolName: "Python",
            classification: .keep,
            confidence: .high,
            reason: "Authored application source under version control.",
            evidence: ["tracked by git"]
        ),
        ScanEntry(
            path: dev("nightwatch-api/.venv"),
            name: ".venv",
            sizeBytes: gb(1.1),
            projectName: "Nightwatch API",
            toolName: "uv",
            classification: .rebuildable,
            confidence: .high,
            reason: "Virtual environment installed from a pinned dependency file.",
            evidence: ["pyproject.toml", "uv.lock"],
            rebuildRecipe: "uv sync"
        ),
    ]

    private static let marrowfield: [ScanEntry] = [
        ScanEntry(
            path: dev("marrowfield/source"),
            name: "source",
            sizeBytes: gb(1.2),
            projectName: "Marrowfield",
            toolName: "Go",
            classification: .keep,
            confidence: .high,
            reason: "Authored source plus checked-in reference datasets.",
            evidence: ["go.mod", "tracked by git"]
        ),
        ScanEntry(
            path: dev("marrowfield/.git/objects"),
            name: ".git objects",
            sizeBytes: gb(2.6),
            projectName: "Marrowfield",
            toolName: "Git",
            classification: .review,
            confidence: .low,
            reason: "Repository history. Some objects may be unreachable, but SLUJ cannot tell which without inspecting refs.",
            evidence: ["large pack files", "no upstream remote configured"]
        ),
    ]

    private static let slujItself: [ScanEntry] = [
        ScanEntry(
            path: dev("sluj/Sources"),
            name: "Sources",
            sizeBytes: mb(3.2),
            projectName: "SLUJ",
            toolName: "Swift",
            classification: .keep,
            confidence: .high,
            reason: "Authored application source under version control.",
            evidence: ["Package.swift", "tracked by git"]
        ),
        ScanEntry(
            path: dev("sluj/.build"),
            name: ".build",
            sizeBytes: gb(1.9),
            projectName: "SLUJ",
            toolName: "SwiftPM",
            classification: .rebuildable,
            confidence: .high,
            reason: "SwiftPM build artifacts compiled from package sources.",
            evidence: ["Package.swift", "Package.resolved"],
            rebuildRecipe: "swift build"
        ),
    ]

    private static let toolStorage: [ScanEntry] = [
        ScanEntry(
            path: lib("Developer/Xcode/DerivedData"),
            name: "DerivedData",
            sizeBytes: gb(9.1),
            toolName: "Xcode",
            classification: .cleanable,
            confidence: .high,
            reason: "Xcode intermediate build products and indexes for 14 projects.",
            evidence: ["Build/", "Index.noindex/"],
            rebuildRecipe: "Rebuilt by Xcode on the next build."
        ),
        ScanEntry(
            path: lib("Developer/Xcode/Archives"),
            name: "Archives",
            sizeBytes: gb(4.8),
            toolName: "Xcode",
            classification: .review,
            confidence: .low,
            reason: "Shipped build archives. These may be the only copy of a released binary's debug symbols.",
            evidence: ["11 .xcarchive bundles", "dSYM payloads present"]
        ),
        ScanEntry(
            path: URL(fileURLWithPath: NSHomeDirectory() + "/.npm/_cacache"),
            name: "cache",
            sizeBytes: gb(3.4),
            toolName: "npm",
            classification: .cleanable,
            confidence: .high,
            reason: "Package download cache. Entries are re-fetched from the registry when needed.",
            evidence: ["_cacache/content-v2", "content-addressable layout"],
            rebuildRecipe: "npm cache clean --force"
        ),
        ScanEntry(
            path: lib("Caches/org.swift.swiftpm"),
            name: "build artifacts",
            sizeBytes: gb(2.7),
            toolName: "SwiftPM",
            classification: .rebuildable,
            confidence: .medium,
            reason: "Shared package checkouts and build artifacts resolved from manifests.",
            evidence: ["manifest cache", "repository checkouts"],
            rebuildRecipe: "swift package resolve"
        ),
        ScanEntry(
            path: lib("Containers/com.docker.docker/Data/vms/0"),
            name: "storage",
            sizeBytes: gb(12.4),
            toolName: "Docker",
            classification: .review,
            confidence: .low,
            reason: "A single opaque disk image holding images, volumes, and containers together.",
            evidence: ["Docker.raw", "sparse disk image"]
        ),
    ]
}
