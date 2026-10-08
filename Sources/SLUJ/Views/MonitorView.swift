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
    @Binding var pinned: Bool
    @AppStorage("metric") private var metric: Metric = .memory
    @State private var hoveringTitle = false
    @State private var showsSettings = false
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
        .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: showsSettings)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button {
                monitor.stopWatching()
            } label: {
                Text(appName)
                    .font(.inter(16))
                    .foregroundStyle(hoveringTitle ? Theme.ink : Theme.muted)
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            .onHover { hoveringTitle = $0 }
            .help("Watching \(appName). Click to choose a different app.")

            Image(systemName: "info.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.icon)
                .help("Busy: CPU over 30% for 10s, or memory over 1 GB.\nHeavy: CPU over 80% for 10s, or memory over 3 GB.")

            Spacer()
            MetricMenu(metric: $metric)
            SettingsButton(isPresented: $showsSettings)
        }
        .frame(height: Dimensions.headerHeight)
        .overlay(alignment: .topTrailing) {
            if showsSettings {
                SettingsDropdown(pinned: $pinned)
                    .offset(y: Dimensions.headerHeight + 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .zIndex(1)
            }
        }
        .zIndex(showsSettings ? 1 : 0)
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
            .frame(height: Dimensions.compactControlHeight)
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

/// Expands the app-level settings panel inside the monitor window.
private struct SettingsButton: View {
    @Binding var isPresented: Bool

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Image(nsImage: SettingsIcon.image)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(Theme.ink)
                .frame(width: Dimensions.compactControlHeight, height: Dimensions.compactControlHeight)
                .background(RoundedRectangle(cornerRadius: 6).fill(Theme.background))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.border))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Settings")
        .accessibilityLabel("Settings")
        .accessibilityValue(isPresented ? "Expanded" : "Collapsed")
    }
}

/// A compact, in-window dropdown with the two settings represented only by
/// their familiar icons; hover help and accessibility labels provide names.
private struct SettingsDropdown: View {
    @Binding var pinned: Bool

    var body: some View {
        VStack(spacing: 4) {
            ThemeToggle()
            PinButton(pinned: $pinned)
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.background))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.border))
    }
}

/// The supplied settings mark, embedded as its original SVG so the button
/// doesn't reinterpret or distort the icon's path data.
private enum SettingsIcon {
    static let image: NSImage = {
        let svg = #"""
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"><path d="M10.53 3.82729C11.4432 3.31361 12.5583 3.31361 13.4715 3.82729L18.4716 6.63977C19.4162 7.17112 20.0008 8.17067 20.0008 9.2545L20.0008 14.7454C20.0008 15.8292 19.4162 16.8288 18.4715 17.3601L13.4715 20.1726C12.5583 20.6863 11.4432 20.6863 10.53 20.1726L5.53008 17.3604C4.58539 16.8291 4.00077 15.8295 4.00077 14.7456L4.00077 9.25448C4.00077 8.17065 4.58536 7.17109 5.53 6.63974L10.53 3.82729Z" stroke="black" stroke-width="2" stroke-linecap="square" stroke-linejoin="round"/><path d="M18.4708 6.63975L13.4708 3.82728C12.5575 3.3136 11.4425 3.3136 10.5292 3.82728L5.52924 6.63973C4.58459 7.17108 4 8.17064 4 9.25447V14.7456C4 15.8295 4.58463 16.8291 5.52931 17.3604L10.5293 20.1726C11.4425 20.6863 12.5575 20.6863 13.4707 20.1726L18.4708 17.3601C19.4154 16.8288 20 15.8292 20 14.7454V9.25449C20 8.17066 19.4154 7.17111 18.4708 6.63975Z" stroke="black" stroke-width="2" stroke-linecap="square" stroke-linejoin="round"/><path d="M12 15C13.6569 15 15 13.6569 15 12C15 10.3431 13.6569 9 12 9C10.3431 9 9 10.3431 9 12C9 13.6569 10.3431 15 12 15Z" stroke="black" stroke-width="2" stroke-linecap="square" stroke-linejoin="round"/></svg>
        """#
        let image = NSImage(data: Data(svg.utf8)) ?? NSImage(size: NSSize(width: 24, height: 24))
        image.isTemplate = true
        return image
    }()
}
