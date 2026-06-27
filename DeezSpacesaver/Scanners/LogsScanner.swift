import Foundation

struct LogsScanner: CleanupScanner {
    let category = CleanupCategory.logs

    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let roots = [
            home.appendingPathComponent("Library/Logs"),
            home.appendingPathComponent("Library/Logs/DiagnosticReports")
        ].filter { FileManager.default.fileExists(atPath: $0.path) }

        var items: [ScannableItem] = []
        let total = roots.count

        for (index, root) in roots.enumerated() {
            let span = 1.0 / Double(max(total, 1))
            let base = Double(index) / Double(max(total, 1))
            items.append(contentsOf: FileScannerHelpers.enumerateFiles(
                in: root,
                categoryID: category.id,
                riskLevel: .safe,
                excludePaths: settings.excludePaths,
                maxDepth: 4,
                progress: progress,
                progressBase: base,
                progressSpan: span
            ) { _, values in
                Int64(values.fileSize ?? 0) > 100_000
            })
        }
        progress.report(progress: 1, message: "Found \(items.count) log files")
        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }
}
