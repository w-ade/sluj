import Foundation

public enum ByteFormatting {
    /// Compact, decimal-unit size string ("8.4 GB", "412 MB").
    ///
    /// Uses `.file` (decimal, matching Finder) so numbers agree with what the
    /// user sees elsewhere on macOS.
    public static func string(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.allowsNonnumericFormatting = false
        return formatter.string(fromByteCount: bytes)
    }
}
