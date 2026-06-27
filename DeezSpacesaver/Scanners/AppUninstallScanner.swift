import Foundation

struct AppUninstallScanner: CleanupScanner {
    let category = CleanupCategory.appUninstall

    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem] {
        progress.reportImmediate(progress: nil, message: "Scanning Applications…")
        let applicationsURL = URL(fileURLWithPath: "/Applications")
        guard FileManager.default.fileExists(atPath: applicationsURL.path) else { return [] }

        let contents = try FileManager.default.contentsOfDirectory(
            at: applicationsURL,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        let apps = contents.filter { $0.pathExtension == "app" }
        var items: [ScannableItem] = []
        let total = apps.count

        for (index, url) in apps.enumerated() {
            let appName = url.deletingPathExtension().lastPathComponent
            progress.report(
                progress: total > 0 ? Double(index) / Double(total) : nil,
                message: appName
            )

            let size = FileScannerHelpers.directorySize(at: url)

            var relatedPaths: [String] = []
            let home = FileManager.default.homeDirectoryForCurrentUser
            let supportDirs = [
                home.appendingPathComponent("Library/Application Support/\(appName)"),
                home.appendingPathComponent("Library/Containers/\(Bundle(path: url.path)?.bundleIdentifier ?? appName)"),
                home.appendingPathComponent("Library/Preferences/\(Bundle(path: url.path)?.bundleIdentifier ?? appName).plist")
            ]
            for support in supportDirs where FileManager.default.fileExists(atPath: support.path) {
                relatedPaths.append(support.path)
            }

            let detail = relatedPaths.isEmpty
                ? "Application bundle"
                : "Includes \(relatedPaths.count) related support location(s)"

            items.append(ScannableItem(
                path: url.path,
                name: appName,
                sizeBytes: size + relatedPaths.reduce(0) { $0 + FileScannerHelpers.directorySize(at: URL(fileURLWithPath: $1)) },
                modifiedDate: try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                categoryID: category.id,
                riskLevel: .caution,
                detail: detail
            ))
        }
        progress.report(progress: 1, message: "Found \(items.count) applications")
        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }
}

extension AppUninstallScanner {
    static func relatedPaths(for appURL: URL) -> [URL] {
        let appName = appURL.deletingPathExtension().lastPathComponent
        let bundleID = Bundle(path: appURL.path)?.bundleIdentifier ?? appName
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            appURL,
            home.appendingPathComponent("Library/Application Support/\(appName)"),
            home.appendingPathComponent("Library/Containers/\(bundleID)"),
            home.appendingPathComponent("Library/Preferences/\(bundleID).plist"),
            home.appendingPathComponent("Library/Caches/\(bundleID)")
        ].filter { FileManager.default.fileExists(atPath: $0.path) }
    }
}
