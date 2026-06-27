import Foundation

struct PackageManagerScanner: CleanupScanner {
    let category = CleanupCategory.packageManagers
    private let runner = SubprocessRunner()

    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem] {
        var items: [ScannableItem] = []
        let home = FileManager.default.homeDirectoryForCurrentUser

        let cachePaths: [(String, String)] = [
            ("Homebrew Cache", home.appendingPathComponent("Library/Caches/Homebrew").path),
            ("npm Cache", home.appendingPathComponent(".npm/_cacache").path),
            ("pnpm Store", home.appendingPathComponent("Library/pnpm/store").path),
            ("yarn Cache", home.appendingPathComponent("Library/Caches/Yarn").path),
            ("pip Cache", home.appendingPathComponent("Library/Caches/pip").path),
            ("Docker Data", home.appendingPathComponent(".docker").path)
        ]

        let existing = cachePaths.filter { FileManager.default.fileExists(atPath: $0.1) }
        let total = max(existing.count, 1)

        for (index, (name, path)) in existing.enumerated() {
            progress.report(
                progress: Double(index) / Double(total),
                message: name
            )
            let url = URL(fileURLWithPath: path)
            let size = FileScannerHelpers.directorySize(at: url, progress: progress, label: name)
            guard size > 5 * 1_024 * 1_024 else { continue }
            items.append(ScannableItem(
                path: path,
                name: name,
                sizeBytes: size,
                categoryID: category.id,
                riskLevel: .safe,
                detail: "Package manager cache — may re-download on next install"
            ))
        }

        if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew") {
            progress.report(progress: nil, message: "Estimating Homebrew cleanup…")
            if let brewSize = try? estimateBrewCleanup() {
                items.append(ScannableItem(
                    path: "brew-cleanup",
                    name: "Homebrew Reclaimable",
                    sizeBytes: brewSize,
                    categoryID: category.id,
                    riskLevel: .safe,
                    detail: "Run brew cleanup via Move to Trash on cache folders, or use brew cleanup in developer tools"
                ))
            }
        }

        progress.report(progress: 1, message: "Found \(items.count) caches")
        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }

    private func estimateBrewCleanup() throws -> Int64 {
        let output = try runner.runShell("/opt/homebrew/bin/brew cleanup -n 2>/dev/null | tail -1")
        let digits = output.filter { $0.isNumber }
        if let mb = Int64(digits), mb > 0 {
            return mb * 1_024 * 1_024
        }
        return 0
    }
}
