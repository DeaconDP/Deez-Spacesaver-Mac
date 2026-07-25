import Foundation

enum SafetyGuard {
    static let denyPrefixes: [String] = [
        "/System",
        "/usr",
        "/bin",
        "/sbin",
        "/var/db",
        "/Library/Apple",
        "/private/var/db"
    ]

    static func normalizedPath(_ path: String) -> String {
        (path as NSString).standardizingPath
    }

    static func canonicalPath(_ path: String) -> String {
        URL(fileURLWithPath: normalizedPath(path))
            .standardizedFileURL
            .resolvingSymlinksInPath()
            .path
    }

    static func isDenied(_ path: String) -> Bool {
        let normalized = normalizedPath(path)
        return denyPrefixes.contains { normalized == $0 || normalized.hasPrefix($0 + "/") }
    }

    static func isExcluded(_ path: String, excludePaths: [String]) -> Bool {
        let normalized = normalizedPath(path)
        return excludePaths.contains { normalized == $0 || normalized.hasPrefix($0 + "/") }
    }

    static func canScan(path: String, excludePaths: [String]) -> Bool {
        !isDenied(path) && !isExcluded(path, excludePaths: excludePaths)
    }

    static func canDelete(item: ScannableItem, category: CleanupCategory, excludePaths: [String]) -> Bool {
        guard canScan(path: item.path, excludePaths: excludePaths) else { return false }
        if item.path.hasPrefix("/Applications/") {
            return category.id == CleanupCategory.appUninstall.id
        }
        return true
    }

    static func isSafeApplicationBundle(
        _ appURL: URL,
        under applicationsRoot: URL = URL(fileURLWithPath: "/Applications", isDirectory: true)
    ) -> Bool {
        guard appURL.pathExtension.localizedCaseInsensitiveCompare("app") == .orderedSame else {
            return false
        }

        let canonicalRoot = canonicalPath(applicationsRoot.path)
        let canonicalApp = canonicalPath(appURL.path)
        guard canonicalApp.hasPrefix(canonicalRoot + "/") else { return false }

        var isDirectory = ObjCBool(false)
        return FileManager.default.fileExists(atPath: canonicalApp, isDirectory: &isDirectory)
            && isDirectory.boolValue
    }

    static func requiresLargeBatchConfirmation(itemCount: Int, totalBytes: Int64) -> Bool {
        itemCount > 500 || totalBytes > 10 * 1_024 * 1_024 * 1_024
    }

    static func resolveSymlinkIfNeeded(_ url: URL) -> URL {
        let resolved = url.resolvingSymlinksInPath()
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if resolved.path.hasPrefix(home) || resolved.path.hasPrefix("/tmp") {
            return resolved
        }
        return url
    }
}
