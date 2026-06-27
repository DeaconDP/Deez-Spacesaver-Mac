import Foundation

struct InstallersScanner: CleanupScanner {
    let category = CleanupCategory.installers
    private let extensions = Set(["dmg", "pkg", "mpkg", "iso"])

    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let roots = [
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Desktop"),
            home
        ].filter { FileManager.default.fileExists(atPath: $0.path) }

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
                maxDepth: root == home ? 1 : 4,
                progress: progress,
                progressBase: base,
                progressSpan: span
            ) { url, _ in
                extensions.contains(url.pathExtension.lowercased())
            }
            items.append(contentsOf: found)
        }

        var seen = Set<String>()
        let result = items.filter { seen.insert($0.path).inserted }
            .sorted { $0.sizeBytes > $1.sizeBytes }
        progress.report(progress: 1, message: "Found \(result.count) installers")
        return result
    }
}
