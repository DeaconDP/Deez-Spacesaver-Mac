import Foundation

struct BrowserCachesScanner: CleanupScanner {
    let category = CleanupCategory.browserCaches

    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let candidates: [(String, String)] = [
            ("Safari", home.appendingPathComponent("Library/Caches/com.apple.Safari").path),
            ("Safari WebKit", home.appendingPathComponent("Library/Caches/com.apple.WebKit.Networking").path),
            ("Chrome", home.appendingPathComponent("Library/Caches/Google/Chrome").path),
            ("Firefox", home.appendingPathComponent("Library/Caches/Firefox").path),
            ("Edge", home.appendingPathComponent("Library/Caches/Microsoft Edge").path)
        ]

        let existing = candidates.filter {
            FileManager.default.fileExists(atPath: $0.1) &&
            SafetyGuard.canScan(path: $0.1, excludePaths: settings.excludePaths)
        }
        let total = max(existing.count, 1)

        var items: [ScannableItem] = []
        for (index, (name, path)) in existing.enumerated() {
            progress.report(
                progress: Double(index) / Double(total),
                message: "\(name) cache"
            )
            let url = URL(fileURLWithPath: path)
            let size = FileScannerHelpers.directorySize(at: url, progress: progress, label: name)
            guard size > 1024 * 1024 else { continue }
            items.append(ScannableItem(
                path: path,
                name: "\(name) Cache",
                sizeBytes: size,
                categoryID: category.id,
                riskLevel: .safe,
                detail: "Browser cache — pages may reload slower once cleared"
            ))
        }
        progress.report(progress: 1, message: "Found \(items.count) browser caches")
        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }
}
