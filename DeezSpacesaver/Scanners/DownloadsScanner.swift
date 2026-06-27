import Foundation

struct DownloadsScanner: CleanupScanner {
    let category = CleanupCategory.downloads

    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem] {
        let downloads = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Downloads")
        guard FileManager.default.fileExists(atPath: downloads.path) else { return [] }

        progress.reportImmediate(progress: nil, message: "Scanning Downloads…")
        let cutoff = Calendar.current.date(byAdding: .day, value: -settings.downloadsMinAgeDays, to: Date()) ?? Date.distantPast
        let largeThreshold = settings.largeFileThresholdBytes

        return FileScannerHelpers.enumerateFiles(
            in: downloads,
            categoryID: category.id,
            riskLevel: .review,
            excludePaths: settings.excludePaths,
            maxDepth: 3,
            progress: progress,
            progressBase: 0,
            progressSpan: 1
        ) { url, values in
            let size = Int64(values.fileSize ?? 0)
            let modified = values.contentModificationDate ?? Date.distantFuture
            let ext = url.pathExtension.lowercased()
            let isInstaller = ["dmg", "zip", "pkg", "iso", "mpkg"].contains(ext)
            return modified < cutoff || size >= largeThreshold || isInstaller
        }
    }
}
