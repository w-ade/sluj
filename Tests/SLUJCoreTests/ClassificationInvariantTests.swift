import Foundation
import Testing
@testable import SLUJCore

private func entry(
    _ classification: StorageClassification,
    size: Int64 = 1_000,
    claimed: Int64? = nil,
    project: String? = "Example",
    tool: String? = "npm"
) -> ScanEntry {
    ScanEntry(
        path: URL(fileURLWithPath: "/tmp/example/thing"),
        sizeBytes: size,
        projectName: project,
        toolName: tool,
        classification: classification,
        confidence: .high,
        reason: "test fixture",
        reclaimableBytes: claimed
    )
}

@Suite("Reclaimable invariants")
struct ReclaimableInvariantTests {
    @Test("KEEP cannot contribute reclaimable bytes")
    func keepIsNeverReclaimable() {
        #expect(entry(.keep).reclaimableBytes == 0)
        // Even when a caller explicitly claims bytes.
        #expect(entry(.keep, claimed: 1_000).reclaimableBytes == 0)
    }

    @Test("REVIEW cannot contribute reclaimable bytes")
    func reviewIsNeverReclaimable() {
        #expect(entry(.review).reclaimableBytes == 0)
        #expect(entry(.review, claimed: 1_000).reclaimableBytes == 0)
    }

    @Test("REBUILDABLE can contribute reclaimable bytes")
    func rebuildableIsReclaimable() {
        #expect(entry(.rebuildable).reclaimableBytes == 1_000)
        #expect(entry(.rebuildable, claimed: 400).reclaimableBytes == 400)
    }

    @Test("CLEANABLE can contribute reclaimable bytes")
    func cleanableIsReclaimable() {
        #expect(entry(.cleanable).reclaimableBytes == 1_000)
    }

    @Test("An entry never claims more than its own size")
    func claimIsClampedToSize() {
        #expect(entry(.cleanable, size: 500, claimed: 9_000).reclaimableBytes == 500)
    }

    @Test("Classification agrees with the entry-level clamp", arguments: StorageClassification.allCases)
    func flagMatchesBehaviour(_ classification: StorageClassification) {
        let value = entry(classification, size: 800).reclaimableBytes
        #expect((value > 0) == classification.canContributeReclaimableBytes)
    }
}

@Suite("Report aggregation")
struct ReportAggregationTests {
    private var report: ScanReport {
        ScanReport(roots: [URL(fileURLWithPath: "/tmp")], entries: [
            entry(.keep, size: 100, project: "A"),
            entry(.rebuildable, size: 800, project: "A"),
            entry(.cleanable, size: 200, project: "B"),
            entry(.review, size: 400, project: "B"),
        ])
    }

    @Test("Totals sum every entry")
    func totalBytes() {
        #expect(report.totalBytes == 1_500)
    }

    @Test("Reclaimable excludes KEEP and REVIEW")
    func reclaimableBytes() {
        #expect(report.reclaimableBytes == 1_000)
    }

    @Test("Review bytes are reported separately and are never reclaimable")
    func reviewBytes() {
        #expect(report.reviewBytes == 400)
        #expect(report.reclaimableBytes + report.reviewBytes <= report.totalBytes)
    }

    @Test("Projects are counted by distinct attribution")
    func projectCount() {
        #expect(report.projectCount == 2)
    }

    @Test("Grouping by project buckets entries and orders by size")
    func groupingByProject() {
        let groups = report.grouped(by: .project)
        #expect(groups.count == 2)
        #expect(groups.first?.name == "A")
        #expect(groups.first?.totalBytes == 900)
        #expect(groups.first?.reclaimableBytes == 800)
    }

    @Test("Grouping by reclaimability buckets by classification label")
    func groupingByReclaimability() {
        let groups = report.grouped(by: .reclaimability)
        #expect(Set(groups.map(\.name)) == ["KEEP", "REBUILDABLE", "CLEANABLE", "REVIEW"])
    }

    @Test("Filtering returns only requested classifications")
    func filtering() {
        let filtered = report.entries(matching: [.rebuildable, .cleanable])
        #expect(filtered.count == 2)
        #expect(filtered.allSatisfy { $0.classification.canContributeReclaimableBytes })
    }
}

@Suite("Ownership")
struct OwnershipTests {
    @Test("Project name is derived from the first component under a root")
    func projectNameFromRoot() {
        let root = URL(fileURLWithPath: "/Users/dev/Developer")
        let path = URL(fileURLWithPath: "/Users/dev/Developer/browser-jot/node_modules")
        #expect(ProjectOwnership.projectName(for: path, roots: [root]) == "browser-jot")
    }

    @Test("Paths outside every root have no project attribution")
    func noAttributionOutsideRoots() {
        let root = URL(fileURLWithPath: "/Users/dev/Developer")
        let path = URL(fileURLWithPath: "/Users/dev/Library/Caches/npm")
        #expect(ProjectOwnership.projectName(for: path, roots: [root]) == nil)
    }
}

@Suite("Scanner contract")
struct ScannerContractTests {
    @Test("v0.1 filesystem scanning is not implemented")
    func filesystemScannerIsNotImplemented() async {
        await #expect(throws: ScannerError.self) {
            try await FilesystemScanner().scan(roots: [URL(fileURLWithPath: "/tmp")])
        }
    }
}
