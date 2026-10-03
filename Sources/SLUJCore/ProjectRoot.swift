/// Finds which project an executable belongs to, by where it lives.
/// `~/Developer/Tools/bench/src-tauri/target/debug/bench` belongs to
/// `~/Developer/Tools/bench`: the developer folder, a category, a name.
public enum ProjectRoot {
    public static func root(forExecutable path: String, developerDirectory: String) -> String? {
        let base = developerDirectory.hasSuffix("/") ? String(developerDirectory.dropLast()) : developerDirectory
        guard path.hasPrefix(base + "/") else { return nil }
        let parts = path.dropFirst(base.count + 1).split(separator: "/")
        // Category, project, and at least one more component below it.
        guard parts.count >= 3 else { return nil }
        return "\(base)/\(parts[0])/\(parts[1])"
    }

    public static func contains(_ path: String, root: String) -> Bool {
        path == root || path.hasPrefix(root + "/")
    }
}
