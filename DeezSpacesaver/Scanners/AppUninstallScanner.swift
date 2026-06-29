import CoreServices
import Foundation

struct AppUninstallScanner: CleanupScanner {
    let category = CleanupCategory.appUninstall

    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem] {
        progress.reportImmediate(progress: nil, message: "Scanning Applications…")
        let cutoff = Calendar.current.date(
            byAdding: .day,
            value: -settings.unusedAppsMinDays,
            to: Date()
        ) ?? Date.distantPast

        let apps = Self.discoverApplicationBundles(excludePaths: settings.excludePaths)
        var items: [ScannableItem] = []
        let total = apps.count

        for (index, url) in apps.enumerated() {
            let appName = url.deletingPathExtension().lastPathComponent
            progress.report(
                progress: total > 0 ? Double(index) / Double(total) : nil,
                message: appName
            )

            let bundleID = Self.bundleIdentifier(at: url)
            let modifiedDate = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
            let lastUsed = Self.lastUsedDate(for: url)

            guard Self.isUnused(lastUsed: lastUsed, modifiedDate: modifiedDate, cutoff: cutoff) else {
                continue
            }

            let related = Self.relatedPaths(for: url)
            let supportPaths = related.filter { $0.path != url.path }
            let size = related.reduce(Int64(0)) { $0 + FileScannerHelpers.directorySize(at: $1) }

            items.append(ScannableItem(
                path: url.path,
                name: appName,
                sizeBytes: size,
                modifiedDate: lastUsed ?? modifiedDate,
                categoryID: category.id,
                riskLevel: .caution,
                detail: Self.detailText(lastUsed: lastUsed, modifiedDate: modifiedDate, supportCount: supportPaths.count)
            ))
        }

        progress.report(progress: 1, message: "Found \(items.count) unused application(s)")
        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }
}

extension AppUninstallScanner {
    static let applicationSearchRoots = [
        URL(fileURLWithPath: "/Applications"),
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
    ]

    static let maxApplicationSearchDepth = 3

    static func discoverApplicationBundles(excludePaths: [String] = []) -> [URL] {
        var apps: [URL] = []
        var seen: Set<String> = []

        for root in applicationSearchRoots {
            guard FileManager.default.fileExists(atPath: root.path) else { continue }
            guard let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            let rootPath = root.path
            for case let url as URL in enumerator {
                let relative = url.path.replacingOccurrences(of: rootPath, with: "")
                let depth = relative.filter { $0 == "/" }.count
                if depth > maxApplicationSearchDepth {
                    enumerator.skipDescendants()
                    continue
                }

                guard url.pathExtension == "app" else { continue }
                enumerator.skipDescendants()

                let standardized = SafetyGuard.normalizedPath(url.path)
                guard !seen.contains(standardized) else { continue }
                guard !shouldSkipApp(at: url, excludePaths: excludePaths) else { continue }

                seen.insert(standardized)
                apps.append(url)
            }
        }

        return apps.sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
    }

    static func shouldSkipApp(at url: URL, excludePaths: [String]) -> Bool {
        let path = SafetyGuard.normalizedPath(url.path)
        guard SafetyGuard.canScan(path: path, excludePaths: excludePaths) else { return true }
        if path == Bundle.main.bundlePath { return true }
        if let bundleID = bundleIdentifier(at: url), isProtectedBundleID(bundleID) { return true }
        return false
    }

    static func isProtectedBundleID(_ bundleID: String) -> Bool {
        bundleID.hasPrefix("com.apple.")
    }

    static func bundleIdentifier(at appURL: URL) -> String? {
        let plistURL = appURL.appendingPathComponent("Contents/Info.plist")
        if let data = FileManager.default.contents(atPath: plistURL.path),
           let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
           let bundleID = plist["CFBundleIdentifier"] as? String {
            return bundleID
        }
        return Bundle(path: appURL.path)?.bundleIdentifier
    }

    static func lastUsedDate(for appURL: URL) -> Date? {
        guard let mdItem = MDItemCreate(kCFAllocatorDefault, appURL.path as CFString) else { return nil }
        return MDItemCopyAttribute(mdItem, kMDItemLastUsedDate) as? Date
    }

    static func isUnused(lastUsed: Date?, modifiedDate: Date?, cutoff: Date) -> Bool {
        let lastActivity: Date
        if let lastUsed {
            lastActivity = lastUsed
        } else if let modifiedDate {
            lastActivity = modifiedDate
        } else {
            return false
        }
        return lastActivity < cutoff
    }

    static func detailText(lastUsed: Date?, modifiedDate: Date?, supportCount: Int) -> String {
        let activity: String
        if let lastUsed {
            let days = max(0, Calendar.current.dateComponents([.day], from: lastUsed, to: Date()).day ?? 0)
            activity = "Last used \(days) day\(days == 1 ? "" : "s") ago"
        } else if let modifiedDate {
            let days = max(0, Calendar.current.dateComponents([.day], from: modifiedDate, to: Date()).day ?? 0)
            activity = "No launch record · bundle modified \(days) day\(days == 1 ? "" : "s") ago"
        } else {
            activity = "No launch record"
        }

        if supportCount > 0 {
            return "\(activity) · \(supportCount) support location\(supportCount == 1 ? "" : "s")"
        }
        return activity
    }

    static func relatedSupportPathCandidates(
        appURL: URL,
        bundleID: String?,
        appName: String,
        library: URL
    ) -> [URL] {
        var paths: [URL] = [appURL]

        if let bundleID {
            paths.append(contentsOf: [
                library.appendingPathComponent("Application Support/\(bundleID)"),
                library.appendingPathComponent("Containers/\(bundleID)"),
                library.appendingPathComponent("Preferences/\(bundleID).plist"),
                library.appendingPathComponent("Caches/\(bundleID)"),
                library.appendingPathComponent("Logs/\(bundleID)"),
                library.appendingPathComponent("WebKit/\(bundleID)"),
                library.appendingPathComponent("HTTPStorages/\(bundleID)"),
                library.appendingPathComponent("Saved Application State/\(bundleID).savedState")
            ])
        }

        paths.append(library.appendingPathComponent("Application Support/\(appName)"))
        return paths
    }

    static func relatedPaths(for appURL: URL) -> [URL] {
        let appName = appURL.deletingPathExtension().lastPathComponent
        let bundleID = bundleIdentifier(at: appURL)
        let library = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library")
        let candidates = relatedSupportPathCandidates(
            appURL: appURL,
            bundleID: bundleID,
            appName: appName,
            library: library
        )

        var seen: Set<String> = []
        return candidates.filter { candidate in
            let path = SafetyGuard.normalizedPath(candidate.path)
            guard !seen.contains(path) else { return false }
            guard FileManager.default.fileExists(atPath: path) else { return false }
            seen.insert(path)
            return true
        }
    }
}
