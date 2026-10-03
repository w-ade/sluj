import AppKit
import SwiftUI
import SLUJCore

/// The watched app: status, four numbers, and the processes behind them.
struct MonitorView: View {
    let monitor: Monitor
    let app: NSRunningApplication
    @Binding var pinned: Bool
    @AppStorage("showProcesses") private var showProcesses = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            metrics
            Divider()
            processes
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            if let icon = app.icon {
                Image(nsImage: icon).resizable().frame(width: 16, height: 16)
            }
            Text(app.localizedName ?? "App")
                .font(.slujTitle)
                .lineLimit(1)
            Button {
                monitor.stopWatching()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Watch a different app")

            Spacer()

            HStack(spacing: 5) {
                Circle().fill(monitor.status.color).frame(width: 8, height: 8)
                Text(monitor.status.label)
                    .font(.slujBody)
                    .foregroundStyle(.secondary)
            }
            .help("Warm: CPU over 30% for 10s, or memory over 1 GB.\nToo heavy: CPU over 80% for 10s, or memory over 3 GB.")

            PinButton(pinned: $pinned)
        }
        .padding(.horizontal, Dimensions.padding)
        .frame(height: 40)
    }

    private var metrics: some View {
        let total = monitor.total
        let limits = Limits.standard
        return VStack(spacing: Dimensions.rowGap) {
            MetricRow(label: "CPU", value: rate(Format.percent(total.cpuPercent)),
                      fraction: total.cpuPercent / 100, color: Palette.cpu)
            MetricRow(label: "Memory", value: Format.bytes(total.memoryBytes),
                      fraction: Double(total.memoryBytes) / Double(limits.memoryHeavy), color: Palette.memory)
            MetricRow(label: "Energy", value: rate(Format.watts(total.watts)),
                      fraction: total.watts / 10, color: Palette.energy)
            MetricRow(label: "GPU", value: rate(Format.percent(total.gpuPercent)),
                      fraction: total.gpuPercent / 100, color: Palette.gpu)
        }
        .padding(Dimensions.padding)
    }

    private var processes: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                showProcesses.toggle()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .rotationEffect(.degrees(showProcesses ? 90 : 0))
                    Text(monitor.processes.count == 1 ? "1 process" : "\(monitor.processes.count) processes")
                    Spacer()
                }
                .font(.slujBody)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Dimensions.padding)
                .frame(height: 32)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showProcesses {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(monitor.processes) { process in
                            HStack(spacing: 8) {
                                Text(process.isMain ? "\(process.name) (main)" : process.name)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer(minLength: 4)
                                Text(rate(Format.percent(process.reading.cpuPercent)))
                                    .frame(width: 36, alignment: .trailing)
                                Text(Format.bytes(process.reading.memoryBytes))
                                    .frame(width: 58, alignment: .trailing)
                            }
                            .font(.slujSmall)
                            .monospacedDigit()
                            .padding(.horizontal, Dimensions.padding)
                            .frame(height: 22)
                        }
                    }
                }
            } else {
                Spacer(minLength: 0)
            }
        }
    }

    /// Rates need two samples; show a dash for the first second.
    private func rate(_ value: String) -> String {
        monitor.hasRates ? value : "–"
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    let fraction: Double
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .leading)
            Text(value)
                .monospacedDigit()
                .frame(width: 66, alignment: .trailing)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * min(1, max(0, fraction)))
                }
            }
            .frame(height: 5)
            .animation(.easeOut(duration: 0.4), value: fraction)
        }
        .font(.slujBody)
        .frame(height: 18)
    }
}
