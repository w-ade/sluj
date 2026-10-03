import AppKit
import SwiftUI
import SLUJCore

enum Metric: String, CaseIterable, Identifiable {
    case cpu = "CPU"
    case memory = "Memory"
    case energy = "Energy"
    case gpu = "GPU"

    var id: String { rawValue }

    /// Memory is a level; the others are rates and need two samples.
    var isRate: Bool { self != .memory }

    func value(_ reading: Reading) -> Double {
        switch self {
        case .cpu: reading.cpuPercent
        case .memory: Double(reading.memoryBytes)
        case .energy: reading.watts
        case .gpu: reading.gpuPercent
        }
    }

    func format(_ value: Double) -> String {
        switch self {
        case .cpu, .gpu: Format.percent(value)
        case .memory: Format.bytes(UInt64(max(0, value)))
        case .energy: Format.watts(value)
        }
    }

    func blurb(for app: String) -> String {
        switch self {
        case .memory:
            "Memory used by each process \(app) runs, including its helpers and the dev server that launched it. The widest bar is where most of it goes. Check it after a change to see if the app got heavier."
        case .cpu:
            "CPU used by each process \(app) runs over the last second, including its helpers and the dev server that launched it. 100% is one full core, so a busy app can pass 100%."
        case .energy:
            "Energy drawn by each process \(app) runs over the last second, including its helpers and dev server. It counts CPU energy only, so it reads lower than Activity Monitor's Energy Impact."
        case .gpu:
            "GPU time used by each process \(app) runs over the last second, including its helpers and dev server. Web views draw through the WebKit GPU process, so look there first."
        }
    }
}

/// The watched app as a card: name and metric, the total, the largest and
/// smallest process, one bar per process, and what the bars mean.
struct MonitorView: View {
    let monitor: Monitor
    let app: NSRunningApplication
    @AppStorage("metric") private var metric: Metric = .memory
    @State private var hoveringTitle = false

    private var appName: String { app.localizedName ?? "App" }
    private var showsValues: Bool { !metric.isRate || monitor.hasRates }

    /// Processes doing any of this metric's work, largest first.
    private var ranked: [ProcessRow] {
        monitor.processes
            .filter { metric.value($0.reading) > 0 }
            .sorted { metric.value($0.reading) > metric.value($1.reading) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            stat
            Spacer().frame(height: Dimensions.sectionGap)
            range
            Spacer().frame(height: 8)
            BarStrip(segments: segments)
                .frame(height: Dimensions.barHeight)
            Spacer().frame(height: Dimensions.sectionGap)
            Rectangle().fill(Theme.border).frame(height: 1)
            Spacer().frame(height: Dimensions.sectionGap)
            Text(metric.blurb(for: appName))
                .font(.inter(12))
                .lineSpacing(1.5)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button {
                monitor.stopWatching()
            } label: {
                Text("sluj")
                    .font(.inter(16))
                    .foregroundStyle(hoveringTitle ? Theme.ink : Theme.muted)
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            .onHover { hoveringTitle = $0 }
            .help("Watching \(appName). Click to watch a different app.")

            Image(systemName: "info.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.icon)
                .help("Warm: CPU over 30% for 10s, or memory over 1 GB.\nToo heavy: CPU over 80% for 10s, or memory over 3 GB.")

            Spacer()
            MetricMenu(metric: $metric)
        }
        .frame(height: Dimensions.headerHeight)
    }

    private var stat: some View {
        HStack(spacing: 12) {
            Text(showsValues ? metric.format(metric.value(monitor.total)) : "–")
                .font(.inter(30))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
            HStack(spacing: 0) {
                Text(monitor.status.label).foregroundStyle(monitor.status.color)
                Text(" · \(monitor.processes.count) \(monitor.processes.count == 1 ? "process" : "processes")")
                    .foregroundStyle(Theme.muted)
            }
            .font(.inter(14))
        }
        .frame(height: Dimensions.statHeight)
    }

    private var range: some View {
        HStack {
            if showsValues, let largest = ranked.first, let smallest = ranked.last {
                Text("\(largest.name) · \(metric.format(metric.value(largest.reading)))")
                Spacer()
                if ranked.count > 1 {
                    Text("\(smallest.name) · \(metric.format(metric.value(smallest.reading)))")
                }
            } else {
                Text(showsValues ? "No \(metric.rawValue) use right now" : "Measuring…")
                Spacer()
            }
        }
        .font(.inter(14))
        .foregroundStyle(Theme.muted)
        .lineLimit(1)
        .frame(height: Dimensions.rangeHeight)
    }

    private var segments: [BarStrip.Segment] {
        guard showsValues else { return [] }
        return ranked.map { process in
            let value = metric.value(process.reading)
            return BarStrip.Segment(
                id: process.id,
                value: value,
                color: Palette.series(process.colorSlot),
                label: "\(process.name) · \(metric.format(value))"
            )
        }
    }
}

/// One rounded bar per process, widths proportional to value, every bar at
/// least a few points wide so the smallest processes stay visible.
struct BarStrip: View {
    struct Segment: Identifiable, Equatable {
        let id: Int32
        let value: Double
        let color: Color
        let label: String
    }

    let segments: [Segment]
    private let minimumWidth: CGFloat = 3

    var body: some View {
        GeometryReader { geometry in
            if segments.isEmpty {
                RoundedRectangle(cornerRadius: Dimensions.barRadius).fill(Theme.border)
            } else {
                let widths = widths(in: geometry.size.width)
                HStack(spacing: Dimensions.barGap) {
                    ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                        RoundedRectangle(cornerRadius: Dimensions.barRadius)
                            .fill(segment.color)
                            .frame(width: widths[index])
                            .help(segment.label)
                    }
                }
            }
        }
        .animation(.easeOut(duration: 0.4), value: segments)
    }

    private func widths(in available: CGFloat) -> [CGFloat] {
        let room = available - Dimensions.barGap * CGFloat(segments.count - 1) - minimumWidth * CGFloat(segments.count)
        let total = segments.reduce(0) { $0 + $1.value }
        return segments.map { minimumWidth + max(0, room) * CGFloat($0.value / total) }
    }
}

/// The bordered "Memory ⌄" select.
struct MetricMenu: View {
    @Binding var metric: Metric

    var body: some View {
        Menu {
            Picker("Metric", selection: $metric) {
                ForEach(Metric.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        } label: {
            HStack(spacing: 8) {
                Text(metric.rawValue)
                    .font(.inter(14))
                    .foregroundStyle(Theme.ink)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.chevron)
                    .frame(width: 16, height: 16)
            }
            .padding(.horizontal, 12)
            .frame(height: Dimensions.headerHeight)
            .background(RoundedRectangle(cornerRadius: 6).fill(Theme.background))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.border))
            .contentShape(Rectangle())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}
