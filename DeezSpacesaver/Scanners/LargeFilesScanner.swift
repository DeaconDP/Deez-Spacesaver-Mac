import Foundation

struct LargeFilesScanner: CleanupScanner {
    let category = CleanupCategory.largeFiles

    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let roots = [
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Movies"),
            home.appendingPathComponent("Pictures")
        ].filter { FileManager.default.fileExists(atPath: $0.path) }

        let threshold = settings.largeFileThresholdBytes
        var items: [ScannableItem] = []
        let total = roots.count

        for (index, root) in roots.enumerated() {
            let span = 1.0 / Double(max(total, 1))
            let base = Double(index) / Double(max(total, 1))
            progress.report(progress: base, message: "Scanning \(root.lastPathComponent)…")

            let found = FileScannerHelpers.enumerateFiles(
                in: root,
                categoryID: category.id,
                riskLevel: .review,
                excludePaths: settings.excludePaths,
                maxDepth: 6,
                progress: progress,
                progressBase: base,
                progressSpan: span
            ) { _, values in
                Int64(values.fileSize ?? 0) >= threshold
            }
            items.append(contentsOf: found)
        }

        progress.report(progress: 1, message: "Found \(items.count) large files")
        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }
}
