import Foundation

protocol CleanupScanner {
    var category: CleanupCategory { get }
    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem]
}

struct FileScannerHelpers {
    static let fileManager = FileManager.default

    static func truncatedPath(_ path: String, maxLength: Int = 48) -> String {
        if path.count <= maxLength { return path }
        let name = (path as NSString).lastPathComponent
        if name.count >= maxLength - 3 {
            return "…" + String(name.suffix(maxLength - 1))
        }
        return "…" + path.suffix(maxLength - 1)
    }

    static func directorySize(at url: URL, progress: ScanProgressReporter? = nil, label: String? = nil) -> Int64 {
        if let progress, let label {
            progress.report(progress: nil, message: "Measuring \(label)…")
        }
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  values.isRegularFile == true else { continue }
            total += Int64(values.fileSize ?? 0)
        }
        return total
    }

    static func item(at url: URL, categoryID: String, riskLevel: RiskLevel, excludePaths: [String], detail: String? = nil) -> ScannableItem? {
        let path = url.path
        guard SafetyGuard.canScan(path: path, excludePaths: excludePaths) else { return nil }

        var isDirectory = ObjCBool(false)
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else { return nil }

        let size: Int64
        if isDirectory.boolValue {
            size = directorySize(at: url)
        } else {
            let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            size = Int64(values?.fileSize ?? 0)
        }

        let modified = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        return ScannableItem(
            path: path,
            sizeBytes: size,
            modifiedDate: modified,
            categoryID: categoryID,
            riskLevel: riskLevel,
            detail: detail
        )
    }

    static func enumerateFiles(
        in root: URL,
        categoryID: String,
        riskLevel: RiskLevel,
        excludePaths: [String],
        maxDepth: Int = 8,
        progress: ScanProgressReporter? = nil,
        progressBase: Double = 0,
        progressSpan: Double = 1,
        filter: ((URL, URLResourceValues) -> Bool)? = nil
    ) -> [ScannableItem] {
        guard SafetyGuard.canScan(path: root.path, excludePaths: excludePaths) else { return [] }
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey, .isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        var items: [ScannableItem] = []
        let rootPath = root.path
        var fileCount = 0

        progress?.reportImmediate(
            progress: progressBase,
            message: "Scanning \(root.lastPathComponent)…"
        )

        for case let url as URL in enumerator {
            let relative = url.path.replacingOccurrences(of: rootPath, with: "")
            let depth = relative.filter { $0 == "/" }.count
            if depth > maxDepth { enumerator.skipDescendants(); continue }

            guard var values = try? url.resourceValues(forKeys: [
                .isRegularFileKey, .fileSizeKey, .contentModificationDateKey
            ]), values.isRegularFile == true else { continue }

            if let filter, !filter(url, values) { continue }
            guard SafetyGuard.canScan(path: url.path, excludePaths: excludePaths) else { continue }

            items.append(ScannableItem(
                path: url.path,
                sizeBytes: Int64(values.fileSize ?? 0),
                modifiedDate: values.contentModificationDate,
                categoryID: categoryID,
                riskLevel: riskLevel
            ))

            fileCount += 1
            if fileCount % 50 == 0 {
                let fraction = min(0.95, Double(fileCount) / Double(fileCount + 100))
                progress?.report(
                    progress: progressBase + fraction * progressSpan,
                    message: truncatedPath(url.path)
                )
            }
        }

        progress?.report(
            progress: progressBase + progressSpan,
            message: "Found \(items.count) items in \(root.lastPathComponent)"
        )
        return items
    }

    static func scanDirectoryListing(
        at root: URL,
        categoryID: String,
        riskLevel: RiskLevel,
        excludePaths: [String],
        progress: ScanProgressReporter,
        detail: String? = nil
    ) throws -> [ScannableItem] {
        guard FileManager.default.fileExists(atPath: root.path) else { return [] }

        let contents = try FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        let total = contents.count
        var items: [ScannableItem] = []

        for (index, url) in contents.enumerated() {
            guard SafetyGuard.canScan(path: url.path, excludePaths: excludePaths) else { continue }
            let name = url.lastPathComponent
            progress.report(
                progress: total > 0 ? Double(index) / Double(total) : nil,
                message: name
            )
            let size = directorySize(at: url)
            guard size > 0 else { continue }
            items.append(ScannableItem(
                path: url.path,
                sizeBytes: size,
                modifiedDate: nil,
                categoryID: categoryID,
                riskLevel: riskLevel,
                detail: detail
            ))
        }
        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }
}
