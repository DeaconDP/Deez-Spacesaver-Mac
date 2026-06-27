import Foundation

struct IOSBackupScanner: CleanupScanner {
    let category = CleanupCategory.iosBackups

    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem] {
        progress.reportImmediate(progress: nil, message: "Checking iOS backups…")
        let backupRoot = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/MobileSync/Backup")
        guard FileManager.default.fileExists(atPath: backupRoot.path) else { return [] }

        let contents = try FileManager.default.contentsOfDirectory(
            at: backupRoot,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        var items: [ScannableItem] = []
        let total = contents.count

        for (index, url) in contents.enumerated() {
            var isDirectory = ObjCBool(false)
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else { continue }

            let infoPlist = url.appendingPathComponent("Info.plist")
            var deviceName = url.lastPathComponent
            if let data = try? Data(contentsOf: infoPlist),
               let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
               let name = plist["Device Name"] as? String ?? plist["Display Name"] as? String {
                deviceName = name
            }

            progress.report(
                progress: total > 0 ? Double(index) / Double(total) : nil,
                message: deviceName
            )

            if let item = FileScannerHelpers.item(
                at: url,
                categoryID: category.id,
                riskLevel: .review,
                excludePaths: settings.excludePaths,
                detail: "Backup: \(deviceName)"
            ) {
                items.append(item)
            }
        }
        progress.report(progress: 1, message: "Found \(items.count) backups")
        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }
}
