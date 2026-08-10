import AppKit
import SwiftUI
import SLUJCore

/// The single SLUJ window.
struct MainView: View {
    @State private var model = ReportViewModel()

    /// `SLUJ --sample` opens straight into the fixture report, so design
    /// iteration and screenshots don't start from the empty state.
    private static var launchesWithSample: Bool {
        CommandLine.arguments.contains("--sample")
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            switch model.state {
            case .empty:
                EmptyStateView(onChooseFolders: chooseFolders, onUseSample: { model.beginScan() })
            case .scanning:
                ScanningView()
            case .loaded(let report):
                ReportView(model: model, report: report)
            }
        }
        .frame(minWidth: 940, minHeight: 620)
        .background(.background)
        .task {
            if Self.launchesWithSample, model.report == nil { model.beginScan() }
        }
    }

    /// The window's own title row. SwiftUI's toolbar placements are not
    /// dependable enough here, and this bar is part of the layout anyway.
    private var header: some View {
        HStack(spacing: 10) {
            Text("SLUJ")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.6)
            Spacer(minLength: 0)
            if model.report != nil {
                Button {
                    model.beginScan(roots: model.chosenRoots)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.accessoryBar)
                .help("Reload the report")
                .accessibilityLabel("Rescan")
            }
            Button("Scan…") { chooseFolders() }
                .controlSize(.small)
                .help("Choose folders to scan")
        }
        .padding(.horizontal, Metric.windowPadding)
        .padding(.vertical, 8)
        .frame(height: 38)
    }

    /// Asks for folders with `NSOpenPanel`. v0.1 records the selection and
    /// shows the fixture report — nothing is read from disk.
    private func chooseFolders() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = "Scan"
        panel.message = "Choose developer folders. SLUJ only reads sizes — it never modifies or deletes files."
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser

        guard panel.runModal() == .OK else { return }
        model.beginScan(roots: panel.urls)
    }
}

struct EmptyStateView: View {
    let onChooseFolders: () -> Void
    let onUseSample: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 10) {
                Text("SLUJ")
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(2)
                Text("See what your developer environment is actually carrying.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Text("SLUJ measures developer storage and separates authored work from material that can be rebuilt. It is read-only: it never deletes, moves, or modifies anything.")
                    .font(.slujBody)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: 400, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Button("Choose folders to scan…", action: onChooseFolders)
                        .controlSize(.large)
                    Button("Use sample report", action: onUseSample)
                        .controlSize(.large)
                        .buttonStyle(.link)
                }
                .padding(.top, 8)
            }
            .frame(maxWidth: 420, alignment: .leading)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Metric.windowPadding)
    }
}

struct ScanningView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
            Text("Measuring developer storage…")
                .font(.slujBody)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
