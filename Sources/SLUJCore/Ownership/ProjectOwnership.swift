import Foundation

/// Attributes storage to the project that owns it.
///
/// Ownership is what makes SLUJ readable: 8 GB of `node_modules` is noise,
/// but 8 GB of *Browser Jot's* `node_modules` is a decision. This type is
/// pure path arithmetic — it performs no filesystem access.
public enum ProjectOwnership {
    /// Files whose presence marks a directory as a project root.
    public static let projectMarkers: [String] = [
        "package.json",
        "Package.swift",
        "Cargo.toml",
        "go.mod",
        "pyproject.toml",
        ".git",
    ]

    /// Derive a human-readable project name from a path, given the developer
    /// roots being scanned (e.g. `~/Developer`).
    ///
    /// `~/Developer/browser-jot/node_modules` under root `~/Developer`
    /// resolves to `browser-jot`.
    public static func projectName(for path: URL, roots: [URL]) -> String? {
        let components = path.standardizedFileURL.pathComponents
        for root in roots {
            let rootComponents = root.standardizedFileURL.pathComponents
            guard components.count > rootComponents.count,
                  Array(components.prefix(rootComponents.count)) == rootComponents
            else { continue }
            return components[rootComponents.count]
        }
        return nil
    }

    /// A display path that keeps the home directory readable as `~`.
    public static func displayPath(for path: URL) -> String {
        let full = path.standardizedFileURL.path
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path
        guard full.hasPrefix(home) else { return full }
        return "~" + String(full.dropFirst(home.count))
    }
}
