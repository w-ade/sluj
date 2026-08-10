import SwiftUI
import SLUJCore

struct ClassificationBadge: View {
    let classification: StorageClassification

    var body: some View {
        Text(classification.label)
            .font(.system(size: 9, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(classification.badgeForeground)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(classification.badgeBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .strokeBorder(
                                classification.stroke,
                                style: StrokeStyle(
                                    lineWidth: 1,
                                    dash: classification.usesDashedStroke ? [2.5, 2.5] : []
                                )
                            )
                    }
            }
    }
}

/// A stat in the header row: large value, small label.
struct StatTile: View {
    let label: String
    let value: String
    var detail: String?
    var isMuted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.slujStatLabel)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.slujStatValue)
                .foregroundStyle(isMuted ? .secondary : .primary)
            if let detail {
                Text(detail)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// A small text row used throughout the inspector: label above, value below.
struct DetailRow: View {
    let label: String
    let value: String
    var monospaced: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.slujSectionLabel)
                .tracking(0.5)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(monospaced ? .slujMono : .slujBody)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
