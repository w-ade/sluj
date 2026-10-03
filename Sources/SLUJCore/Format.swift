import Foundation

public enum Format {
    /// Binary units, matching Activity Monitor.
    public static func bytes(_ bytes: UInt64) -> String {
        let megabytes = Double(bytes) / 1_048_576
        if megabytes < 1024 { return "\(Int(megabytes.rounded())) MB" }
        return String(format: "%.1f GB", megabytes / 1024)
    }

    public static func percent(_ value: Double) -> String {
        String(format: "%.0f%%", value)
    }

    /// Light apps draw tens of milliwatts, so small values read in mW.
    public static func watts(_ value: Double) -> String {
        if value < 1 { return "\(Int((value * 1000).rounded())) mW" }
        return String(format: value < 10 ? "%.2f W" : "%.1f W", value)
    }
}

/// Readable names for the processes in an app's breakdown.
public enum ProcessName {
    static let scriptRunners: Set<String> = ["node", "bun", "deno"]
    static let genericScripts: Set<String> = ["cli", "index", "bin", "main"]

    public static func needsArguments(_ name: String) -> Bool {
        scriptRunners.contains(name)
    }

    public static func display(name: String, arguments: [String]) -> String {
        switch name {
        case "com.apple.WebKit.WebContent": return "Web Content"
        case "com.apple.WebKit.Networking": return "Networking"
        case "com.apple.WebKit.GPU": return "WebKit GPU"
        default: break
        }
        guard scriptRunners.contains(name) else { return name }

        // Tools like npm overwrite their arguments with a title ("npm run app").
        if let title = arguments.first, title.contains(" ") { return title }
        guard let script = arguments.dropFirst().first(where: { !$0.isEmpty && !$0.hasPrefix("-") }) else { return name }

        // node …/node_modules/.bin/vite → "vite (node)"
        let url = URL(fileURLWithPath: script)
        var file = url.deletingPathExtension().lastPathComponent
        if genericScripts.contains(file) {
            file = url.deletingLastPathComponent().lastPathComponent
            if file == "bin" { file = url.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent }
        }
        return "\(file) (\(name))"
    }
}
