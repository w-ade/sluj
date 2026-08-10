import Foundation

/// The interface a real filesystem scanner will implement.
///
/// # Read-only guarantee
///
/// SLUJ never deletes, moves, trashes, or modifies user files. Any conforming
/// scanner must restrict itself to metadata reads (enumeration, file sizes,
/// existence checks). It must not:
///
/// - call `FileManager.removeItem` / `trashItem` / `moveItem` / `copyItem`
/// - write to any path outside its own scratch space
/// - shell out to deletion or cleanup commands
/// - request Full Disk Access automatically or escalate privileges
///
/// Conformances are expected to honour user-granted folder access only.
public protocol StorageScanner: Sendable {
    /// Measure and classify developer storage beneath the given roots.
    /// Implementations must be read-only.
    func scan(roots: [URL]) async throws -> ScanReport
}

/// Not implemented in v0.1.
///
/// The UI currently runs entirely on `FixtureReport`. This placeholder exists
/// so the app can be wired against the real interface without a real crawler,
/// and so the read-only contract is documented at the seam where it matters.
public struct FilesystemScanner: StorageScanner {
    public init() {}

    public func scan(roots: [URL]) async throws -> ScanReport {
        throw ScannerError.notImplemented
    }
}

public enum ScannerError: Error, LocalizedError {
    case notImplemented

    public var errorDescription: String? {
        switch self {
        case .notImplemented:
            "Filesystem scanning is not implemented in this version. SLUJ is running on fixture data."
        }
    }
}
