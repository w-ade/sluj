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
            "Memory used by each process \(app) runs, including its helpers and the dev server that launched it. The tallest column is where most of it goes. Check it after a change to see if the app got heavier."
        case .cpu:
            "CPU used by each process \(app) runs over the last second, including its helpers and the dev server that launched it. 100% is one full core, so a busy app can pass 100%."
        case .energy:
            "Energy drawn by each process \(app) runs over the last second, including its helpers and dev server. It counts CPU energy only, so it reads lower than Activity Monitor's Energy Impact."
        case .gpu:
            "GPU time used by each process \(app) runs over the last second, including its helpers and dev server. Web views draw through the WebKit GPU process, so look there first."
        }
    }
}

/// The watched app as a card with a labeled column for every process.
struct MonitorView: View {
    let monitor: Monitor
    let app: NSRunningApplication
    @AppStorage("metric") private var metric: Metric = .memory
    @State private var hoveringTitle = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var appName: String { app.localizedName ?? "App" }
    private var showsValues: Bool { !metric.isRate || monitor.hasRates }

    /// Keep idle processes visible too. Stable tie-breaking avoids jitter
    /// when several helpers have the same (often zero) rate.
    private var ranked: [ProcessRow] {
        monitor.processes
            .sorted {
                let lhs = metric.value($0.reading), rhs = metric.value($1.reading)
                return lhs == rhs ? $0.id < $1.id : lhs > rhs
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            stat
            Spacer().frame(height: Dimensions.sectionGap)
            ProcessChart(segments: segments, emptyMessage: showsValues ? "No processes to display" : "Measuring…")
            Spacer().frame(height: Dimensions.sectionGap)
            Rectangle().fill(Theme.border).frame(height: 1)
            Spacer().frame(height: Dimensions.sectionGap)
            Text(metric.blurb(for: appName))
                .font(.inter(12))
                .lineSpacing(2)
                .foregroundStyle(Theme.description)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .help(metric.blurb(for: appName))
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
                .help("Busy: CPU over 30% for 10s, or memory over 1 GB.\nHeavy: CPU over 80% for 10s, or memory over 3 GB.")

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
                .contentTransition(.numericText(value: metric.value(monitor.total)))
                .animation(reduceMotion ? nil : .smooth(duration: 0.35), value: metric.value(monitor.total))
            HStack(spacing: 0) {
                Text(monitor.status.label).foregroundStyle(monitor.status.color)
                Text(" · \(monitor.processes.count) \(monitor.processes.count == 1 ? "process" : "processes")")
                    .foregroundStyle(Theme.muted)
            }
            .font(.inter(14))
        }
        .frame(height: Dimensions.statHeight)
    }

    private var segments: [ProcessChart.Segment] {
        guard showsValues else { return [] }
        return ranked.map { process in
            let value = metric.value(process.reading)
            return ProcessChart.Segment(
                id: process.id,
                value: value,
                color: Palette.series(process.colorSlot),
                name: process.name,
                formattedValue: metric.format(value)
            )
        }
    }
}

/// Equal-width columns, normalized to the largest process. Eight fit the
/// design at full size; larger process groups scroll without hiding data.
struct ProcessChart: View {
    struct Segment: Identifiable, Equatable {
        let id: Int32
        let value: Double
        let color: Color
        let name: String
        let formattedValue: String

        var displayName: String {
            if name == "Networking" { return "Network" }
            for suffix in [" (node)", " (bun)", " (deno)"] where name.hasSuffix(suffix) {
                return String(name.dropLast(suffix.count))
            }
            return name
        }

        var accessibilityLabel: String { "\(name) · \(formattedValue)" }
    }

    let segments: [Segment]
    let emptyMessage: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            if segments.isEmpty {
                Text(emptyMessage)
                    .font(.inter(12))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let visibleCount = min(8, segments.count)
                let width = max(1, (geometry.size.width - Dimensions.barGap * CGFloat(visibleCount - 1)) / CGFloat(visibleCount))
                let maximum = segments.map(\.value).max() ?? 0
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: Dimensions.barGap) {
                        ForEach(segments) { segment in
                            column(segment, width: width, maximum: maximum)
                                .transition(.opacity)
                        }
                    }
                    .background(alignment: .top) {
                        Rectangle().fill(Theme.border)
                            .frame(height: 1)
                            .offset(y: Dimensions.plotHeight)
                    }
                    .animation(reduceMotion ? nil : .smooth(duration: 0.4), value: segments)
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(height: Dimensions.chartHeight)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Usage by process")
    }

    private func column(_ segment: Segment, width: CGFloat, maximum: Double) -> some View {
        let height = maximum > 0 ? max(2, Dimensions.barHeight * CGFloat(segment.value / maximum)) : 2
        return VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text(segment.formattedValue)
                    .font(.inter(11))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(height: 14)
                    .transaction { $0.animation = nil }
                UnevenRoundedRectangle(topLeadingRadius: Dimensions.barRadius, topTrailingRadius: Dimensions.barRadius)
                    .fill(segment.color)
                    .frame(height: height)
            }
            .frame(height: Dimensions.plotHeight, alignment: .bottom)
            Color.clear.frame(height: 1)
            Text(segment.displayName)
                .font(.inter(11))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .lineSpacing(1)
                .frame(width: width)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .frame(height: Dimensions.chartLabelHeight, alignment: .top)
        }
        .frame(width: width)
        .help(segment.accessibilityLabel)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(segment.accessibilityLabel)
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
