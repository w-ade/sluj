import SwiftUI
import SLUJCore

/// One rectangle in the treemap. Sized by its frame; placed by the parent.
struct TreemapCell: View {
    let entry: ScanEntry
    let size: CGSize
    let isSelected: Bool
    let onSelect: () -> Void

    private var showsLabel: Bool { size.width > 62 && size.height > 26 }
    private var showsSize: Bool { size.width > 62 && size.height > 42 }

    var body: some View {
        Button(action: onSelect) {
            cell
        }
        .buttonStyle(.plain)
        .help("\(entry.name) — \(ByteFormatting.string(entry.sizeBytes)) — \(entry.classification.label)")
        .accessibilityLabel("\(entry.name), \(ByteFormatting.string(entry.sizeBytes)), \(entry.classification.label)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var cell: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Metric.cellRadius, style: .continuous)
                .fill(entry.classification.fill)
                .overlay {
                    RoundedRectangle(cornerRadius: Metric.cellRadius, style: .continuous)
                        .strokeBorder(
                            isSelected ? Color.accentColor : entry.classification.stroke,
                            style: StrokeStyle(
                                lineWidth: isSelected ? 2 : 1,
                                dash: entry.classification.usesDashedStroke && !isSelected ? [3, 3] : []
                            )
                        )
                }

            if showsLabel {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if showsSize {
                        Text(ByteFormatting.string(entry.sizeBytes))
                            .font(.system(size: 10).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 6)
                .allowsHitTesting(false)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .clipped()
        .contentShape(Rectangle())
    }
}

/// The visualization.
///
/// Groups are laid out proportionally, then each group's entries are laid out
/// inside their own rectangle. Everything is resolved to absolute rectangles
/// in one pass and drawn into a single flat, top-leading layer — no nested
/// greedy containers, so nothing can escape the pane's bounds.
struct TreemapView: View {
    let groups: [ScanGroup]
    let selectedID: ScanEntry.ID?
    let onSelect: (ScanEntry) -> Void

    private static let headerHeight: CGFloat = 17
    private static let groupGap: CGFloat = 5
    private static let cellGap: CGFloat = 2

    private struct PlacedHeader: Identifiable {
        let id: String
        let rect: CGRect
        let name: String
        let bytes: Int64
    }

    private struct PlacedCell: Identifiable {
        let id: ScanEntry.ID
        let rect: CGRect
        let entry: ScanEntry
    }

    var body: some View {
        GeometryReader { proxy in
            let layout = resolve(in: CGRect(origin: .zero, size: proxy.size))

            ZStack(alignment: .topLeading) {
                Color.clear

                ForEach(layout.headers) { header in
                    HStack(spacing: 6) {
                        Text(header.name)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(ByteFormatting.string(header.bytes))
                            .font(.system(size: 10).monospacedDigit())
                            .foregroundStyle(.tertiary)
                        Spacer(minLength: 0)
                    }
                    .frame(width: header.rect.width, height: header.rect.height, alignment: .leading)
                    .clipped()
                    .offset(x: header.rect.minX, y: header.rect.minY)
                }

                ForEach(layout.cells) { cell in
                    TreemapCell(
                        entry: cell.entry,
                        size: cell.rect.size,
                        isSelected: cell.entry.id == selectedID,
                        onSelect: { onSelect(cell.entry) }
                    )
                    .offset(x: cell.rect.minX, y: cell.rect.minY)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .clipped()
        }
    }

    /// Resolve groups and their entries into absolute rectangles.
    private func resolve(in bounds: CGRect) -> (headers: [PlacedHeader], cells: [PlacedCell]) {
        var headers: [PlacedHeader] = []
        var cells: [PlacedCell] = []

        let groupTiles = TreemapLayout.tiles(for: groups, in: bounds) { Double($0.totalBytes) }

        for groupTile in groupTiles {
            let inner = groupTile.rect.insetBy(dx: Self.groupGap / 2, dy: Self.groupGap / 2)
            guard inner.width > 1, inner.height > 1 else { continue }

            let showsHeader = inner.height > 56 && inner.width > 70
            if showsHeader {
                headers.append(PlacedHeader(
                    id: groupTile.value.id,
                    rect: CGRect(x: inner.minX, y: inner.minY, width: inner.width, height: Self.headerHeight),
                    name: groupTile.value.name,
                    bytes: groupTile.value.totalBytes
                ))
            }

            let contentRect = CGRect(
                x: inner.minX,
                y: inner.minY + (showsHeader ? Self.headerHeight : 0),
                width: inner.width,
                height: max(0, inner.height - (showsHeader ? Self.headerHeight : 0))
            )
            guard contentRect.width > 1, contentRect.height > 1 else { continue }

            let entryTiles = TreemapLayout.tiles(for: groupTile.value.entries, in: contentRect) {
                Double($0.sizeBytes)
            }
            for entryTile in entryTiles {
                let rect = entryTile.rect.insetBy(dx: Self.cellGap / 2, dy: Self.cellGap / 2)
                guard rect.width > 0.5, rect.height > 0.5 else { continue }
                cells.append(PlacedCell(id: entryTile.value.id, rect: rect, entry: entryTile.value))
            }
        }

        return (headers, cells)
    }
}
