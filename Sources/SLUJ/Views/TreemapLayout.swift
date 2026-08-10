import CoreGraphics
import Foundation

/// A rectangle produced by the layout, tagged with the value it represents.
struct TreemapTile<Value: Identifiable>: Identifiable {
    var id: Value.ID { value.id }
    let value: Value
    let rect: CGRect
}

/// Squarified treemap layout.
///
/// Kept free of SwiftUI and of SLUJ's own model types so it can be swapped
/// for a better algorithm — or tested — without touching the views.
/// Based on Bruls, Huizing & van Wijk (2000).
enum TreemapLayout {
    /// Lay `items` out inside `rect`, sized proportionally to `weight`.
    /// Items with non-positive weight are dropped.
    static func tiles<Value: Identifiable>(
        for items: [Value],
        in rect: CGRect,
        weight: (Value) -> Double
    ) -> [TreemapTile<Value>] {
        let candidates = items
            .map { (value: $0, weight: weight($0)) }
            .filter { $0.weight > 0 }
            .sorted { $0.weight > $1.weight }

        guard !candidates.isEmpty, rect.width > 0, rect.height > 0 else { return [] }

        let total = candidates.reduce(0) { $0 + $1.weight }
        let scale = Double(rect.width * rect.height) / total

        var results: [TreemapTile<Value>] = []
        var remaining = candidates.map { (value: $0.value, area: $0.weight * scale) }
        var frame = rect

        while !remaining.isEmpty {
            var row: [(value: Value, area: Double)] = []
            let shortSide = Double(min(frame.width, frame.height))

            // Grow the row while doing so improves the worst aspect ratio.
            while !remaining.isEmpty {
                let candidate = row + [remaining[0]]
                if row.isEmpty || worstAspectRatio(candidate, shortSide: shortSide)
                    <= worstAspectRatio(row, shortSide: shortSide) {
                    row = candidate
                    remaining.removeFirst()
                } else {
                    break
                }
            }

            let rowArea = row.reduce(0) { $0 + $1.area }
            let horizontal = frame.width >= frame.height
            let thickness = shortSide > 0 ? CGFloat(rowArea / shortSide) : 0

            var offset: CGFloat = horizontal ? frame.minY : frame.minX
            for item in row {
                let length = rowArea > 0 ? CGFloat(item.area / rowArea) * shortSide : 0
                let tileRect = horizontal
                    ? CGRect(x: frame.minX, y: offset, width: thickness, height: length)
                    : CGRect(x: offset, y: frame.minY, width: length, height: thickness)
                results.append(TreemapTile(value: item.value, rect: tileRect))
                offset += length
            }

            frame = horizontal
                ? CGRect(x: frame.minX + thickness, y: frame.minY,
                         width: max(0, frame.width - thickness), height: frame.height)
                : CGRect(x: frame.minX, y: frame.minY + thickness,
                         width: frame.width, height: max(0, frame.height - thickness))

            if frame.width <= 0.5 || frame.height <= 0.5 { break }
        }

        return results
    }

    /// The worst width/height ratio in a row laid along `shortSide`.
    private static func worstAspectRatio<Value>(
        _ row: [(value: Value, area: Double)],
        shortSide: Double
    ) -> Double {
        guard !row.isEmpty, shortSide > 0 else { return .infinity }
        let total = row.reduce(0) { $0 + $1.area }
        guard total > 0 else { return .infinity }
        let maxArea = row.map(\.area).max() ?? 0
        let minArea = row.map(\.area).min() ?? 0
        let side2 = shortSide * shortSide
        let total2 = total * total
        return max(side2 * maxArea / total2, total2 / (side2 * minArea))
    }
}
