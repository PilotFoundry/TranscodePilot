import Foundation

public enum TemporaryCleanup {
    public static func removeStaleDirectories(in directory: URL,
                                             prefixes: [String],
                                             olderThan: TimeInterval = 86_400,
                                             now: Date = Date()) -> [URL] {
        let fm = FileManager.default
        guard let urls = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: []
        ) else { return [] }
        var removed: [URL] = []
        for url in urls {
            let name = url.lastPathComponent
            guard prefixes.contains(where: { name.hasPrefix($0) }),
                  let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey]),
                  values.isDirectory == true,
                  let modified = values.contentModificationDate,
                  now.timeIntervalSince(modified) > olderThan else { continue }
            if (try? fm.removeItem(at: url)) != nil { removed.append(url) }
        }
        return removed
    }

    public static func removeStaleOutputTemps(in directory: URL, olderThan: TimeInterval = 86_400) -> [URL] {
        removeStaleDirectories(in: directory, prefixes: [".transcodepilot-"], olderThan: olderThan)
    }

    public static func removeStaleProcessTemps(olderThan: TimeInterval = 86_400) -> [URL] {
        removeStaleDirectories(in: FileManager.default.temporaryDirectory,
                               prefixes: ["transcodepilot-process-"],
                               olderThan: olderThan)
    }
}
