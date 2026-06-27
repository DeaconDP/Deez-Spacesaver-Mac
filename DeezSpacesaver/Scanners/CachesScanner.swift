import Foundation

struct CachesScanner: CleanupScanner {
    let category = CleanupCategory.userCaches

    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem] {
        let cachesRoot = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches")
        return try FileScannerHelpers.scanDirectoryListing(
            at: cachesRoot,
            categoryID: category.id,
            riskLevel: .safe,
            excludePaths: settings.excludePaths,
            progress: progress,
            detail: "App cache folder"
        )
    }
}
