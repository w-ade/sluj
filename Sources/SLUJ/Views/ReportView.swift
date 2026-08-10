import SwiftUI
import SLUJCore

/// The loaded state: stats, mode switch, filters, map, inspector.
struct ReportView: View {
    @Bindable var model: ReportViewModel
    let report: ScanReport

    var body: some View {
        VStack(spacing: 0) {
            statsRow
            Divider()
            controlsRow
            Divider()
            HStack(spacing: 0) {
                TreemapView(
                    groups: model.groups,
                    selectedID: model.selectedEntryID,
                    onSelect: { model.select($0) }
                )
                .padding(Metric.windowPadding - 6)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { model.select(nil) }

                Divider()

                InspectorView(entry: model.selectedEntry)
            }
        }
    }

    private var statsRow: some View {
        HStack(alignment: .top, spacing: 24) {
            StatTile(
                label: "Developer storage",
                value: ByteFormatting.string(report.totalBytes),
                detail: "\(report.entries.count) locations"
            )
            StatTile(
                label: "Reclaimable",
                value: ByteFormatting.string(report.reclaimableBytes),
                detail: "Rebuildable and cleanable"
            )
            StatTile(
                label: "Needs review",
                value: ByteFormatting.string(report.reviewBytes),
                detail: "Not counted as reclaimable",
                isMuted: true
            )
            StatTile(
                label: "Projects",
                value: "\(report.projectCount)",
                detail: "Attributed by ownership"
            )
        }
        .padding(.horizontal, Metric.windowPadding)
        .padding(.vertical, 16)
    }

    private var controlsRow: some View {
        HStack(spacing: 14) {
            Picker("", selection: $model.grouping) {
                ForEach(GroupingDimension.allCases, id: \.self) { dimension in
                    Text(dimension.label).tag(dimension)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()

            Divider().frame(height: 16)

            HStack(spacing: 6) {
                ForEach(StorageClassification.allCases, id: \.self) { classification in
                    FilterChip(
                        classification: classification,
                        isOn: model.visibleClassifications.contains(classification),
                        bytes: report.bytes(for: classification),
                        action: { model.toggle(classification) }
                    )
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Metric.windowPadding)
        .padding(.vertical, 9)
    }
}

struct FilterChip: View {
    let classification: StorageClassification
    let isOn: Bool
    let bytes: Int64
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(classification.fill)
                    .overlay {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .strokeBorder(
                                classification.stroke,
                                style: StrokeStyle(
                                    lineWidth: 1,
                                    dash: classification.usesDashedStroke ? [2, 2] : []
                                )
                            )
                    }
                    .frame(width: 9, height: 9)
                Text(classification.label)
                    .font(.system(size: 10, weight: .medium))
                    .tracking(0.4)
                Text(ByteFormatting.string(bytes))
                    .font(.system(size: 10).monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: Metric.controlRadius, style: .continuous)
                    .fill(Color.primary.opacity(isOn ? 0.06 : 0))
                    .overlay {
                        RoundedRectangle(cornerRadius: Metric.controlRadius, style: .continuous)
                            .strokeBorder(Color.primary.opacity(isOn ? 0.10 : 0.05))
                    }
            }
            .opacity(isOn ? 1 : 0.4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(classification.help)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
