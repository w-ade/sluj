import SwiftUI
import SLUJCore

struct InspectorView: View {
    let entry: ScanEntry?

    var body: some View {
        ScrollView {
            if let entry {
                content(for: entry)
            } else {
                placeholder
            }
        }
        .frame(width: Metric.inspectorWidth)
        .background(.background)
    }

    private var placeholder: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Nothing selected")
                .font(.system(size: 12, weight: .medium))
            Text("Select a block in the map to see what SLUJ knows about it.")
                .font(.slujBody)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Metric.windowPadding)
    }

    private func content(for entry: ScanEntry) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.name)
                    .font(.system(size: 15, weight: .medium))
                    .textSelection(.enabled)
                HStack(spacing: 8) {
                    Text(ByteFormatting.string(entry.sizeBytes))
                        .font(.system(size: 12).monospacedDigit())
                        .foregroundStyle(.secondary)
                    ClassificationBadge(classification: entry.classification)
                }
                Text(entry.confidence.label)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            Divider()

            DetailRow(
                label: "PATH",
                value: ProjectOwnership.displayPath(for: entry.path),
                monospaced: true
            )

            HStack(alignment: .top, spacing: 12) {
                if let project = entry.projectName {
                    DetailRow(label: "PROJECT", value: project)
                }
                if let tool = entry.toolName {
                    DetailRow(label: "TOOL", value: tool)
                }
            }

            Divider()

            if entry.needsReview {
                reviewNotice(for: entry)
            } else {
                DetailRow(label: "WHY", value: entry.reason)
            }

            if !entry.evidence.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("EVIDENCE")
                        .font(.slujSectionLabel)
                        .tracking(0.5)
                        .foregroundStyle(.tertiary)
                    ForEach(entry.evidence, id: \.self) { item in
                        Text(item)
                            .font(.slujMono)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let recipe = entry.rebuildRecipe {
                VStack(alignment: .leading, spacing: 5) {
                    Text("REBUILD")
                        .font(.slujSectionLabel)
                        .tracking(0.5)
                        .foregroundStyle(.tertiary)
                    Text(recipe)
                        .font(.slujMono)
                        .textSelection(.enabled)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            RoundedRectangle(cornerRadius: Metric.controlRadius, style: .continuous)
                                .fill(Color.primary.opacity(0.045))
                        }
                }
            }

            reclaimableFooter(for: entry)
        }
        .padding(Metric.windowPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reviewNotice(for entry: ScanEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SLUJ does not currently have enough evidence to safely classify this storage.")
                .font(.slujBody)
                .fixedSize(horizontal: false, vertical: true)
            Text(entry.reason)
                .font(.slujBody)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reclaimableFooter(for entry: ScanEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
                .padding(.bottom, 4)
            if entry.reclaimableBytes > 0 {
                Text("Counted as \(ByteFormatting.string(entry.reclaimableBytes)) reclaimable.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } else {
                Text("Not included in reclaimable total.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Text("SLUJ is read-only. It never deletes anything.")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
