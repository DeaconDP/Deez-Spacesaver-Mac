import Foundation

struct TrashScanner: CleanupScanner {
    let category = CleanupCategory.trash

    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem] {
        progress.reportImmediate(progress: nil, message: "Checking Trash…")
        let home = FileManager.default.homeDirectoryForCurrentUser
        let trashURL = home.appendingPathComponent(".Trash")
        guard FileManager.default.fileExists(atPath: trashURL.path) else { return [] }

        var items: [ScannableItem] = []
        let contents = try FileManager.default.contentsOfDirectory(
            at: trashURL,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        let total = contents.count
        for (index, url) in contents.enumerated() {
            progress.report(
                progress: total > 0 ? Double(index) / Double(total) : nil,
                message: url.lastPathComponent
            )
            if let item = FileScannerHelpers.item(
                at: url,
                categoryID: category.id,
                riskLevel: .safe,
                excludePaths: settings.excludePaths
            ) {
                items.append(item)
            }
        }
        progress.report(progress: 1, message: "Found \(items.count) items in Trash")
        return items
    }
}
