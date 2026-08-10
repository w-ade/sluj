import Foundation
import Observation
import SLUJCore

/// Drives the single window: which report is loaded, how it is grouped,
/// which classifications are visible, and what the inspector is showing.
@Observable
@MainActor
final class ReportViewModel {
    enum State {
        case empty
        case scanning
        case loaded(ScanReport)
    }

    private(set) var state: State = .empty
    var grouping: GroupingDimension = .project
    var visibleClassifications: Set<StorageClassification> = Set(StorageClassification.allCases)
    var selectedEntryID: ScanEntry.ID?

    /// Roots the user picked in the open panel. Recorded for display only —
    /// v0.1 never reads their contents.
    private(set) var chosenRoots: [URL] = []

    var report: ScanReport? {
        if case .loaded(let report) = state { return report }
        return nil
    }

    var isScanning: Bool {
        if case .scanning = state { return true }
        return false
    }

    /// Entries passing the classification filter, largest first.
    var visibleEntries: [ScanEntry] {
        guard let report else { return [] }
        return report.entries(matching: visibleClassifications)
            .sorted { $0.sizeBytes > $1.sizeBytes }
    }

    var groups: [ScanGroup] {
        guard let report else { return [] }
        return report.grouped(by: grouping)
            .compactMap { group in
                let kept = group.entries.filter { visibleClassifications.contains($0.classification) }
                return kept.isEmpty ? nil : ScanGroup(name: group.name, entries: kept)
            }
    }

    var selectedEntry: ScanEntry? {
        guard let selectedEntryID else { return nil }
        return report?.entries.first { $0.id == selectedEntryID }
    }

    // MARK: - Actions

    /// v0.1: no filesystem is touched. The chosen roots are recorded and the
    /// fixture report is presented in their place.
    func beginScan(roots: [URL] = []) {
        chosenRoots = roots
        state = .scanning
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(650))
            let report = FixtureReport.make()
            state = .loaded(report)
            selectedEntryID = report.entries
                .filter(\.classification.canContributeReclaimableBytes)
                .max { $0.sizeBytes < $1.sizeBytes }?
                .id
        }
    }

    func reset() {
        state = .empty
        selectedEntryID = nil
        chosenRoots = []
    }

    func toggle(_ classification: StorageClassification) {
        if visibleClassifications.contains(classification) {
            // Never let the user filter everything away.
            guard visibleClassifications.count > 1 else { return }
            visibleClassifications.remove(classification)
        } else {
            visibleClassifications.insert(classification)
        }
        if let selectedEntry, !visibleClassifications.contains(selectedEntry.classification) {
            selectedEntryID = nil
        }
    }

    func select(_ entry: ScanEntry?) {
        selectedEntryID = entry?.id
    }
}
