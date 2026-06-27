import Foundation

struct MailAttachmentsScanner: CleanupScanner {
    let category = CleanupCategory.mailAttachments

    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem] {
        guard FullDiskAccessService().hasFullDiskAccess() else {
            throw ScanAccessError.fullDiskAccessRequired
        }

        progress.reportImmediate(progress: nil, message: "Scanning Mail attachments…")
        let mailRoot = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mail")

        var items: [ScannableItem] = []
        guard let enumerator = FileManager.default.enumerator(
            at: mailRoot,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var fileCount = 0
        for case let url as URL in enumerator {
            guard url.lastPathComponent == "Attachments" || url.path.contains("/Attachments/") else { continue }
            guard var values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey]),
                  values.isRegularFile == true else { continue }
            let size = Int64(values.fileSize ?? 0)
            guard size > 500_000 else { continue }

            fileCount += 1
            if fileCount % 25 == 0 {
                progress.report(progress: nil, message: FileScannerHelpers.truncatedPath(url.path))
            }

            items.append(ScannableItem(
                path: url.path,
                sizeBytes: size,
                modifiedDate: values.contentModificationDate,
                categoryID: category.id,
                riskLevel: .review,
                detail: "Mail attachment cache"
            ))
        }
        progress.report(progress: 1, message: "Found \(items.count) attachments")
        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }
}

struct MessagesAttachmentsScanner: CleanupScanner {
    let category = CleanupCategory.messagesAttachments

    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem] {
        guard FullDiskAccessService().hasFullDiskAccess() else {
            throw ScanAccessError.fullDiskAccessRequired
        }

        progress.reportImmediate(progress: nil, message: "Scanning Messages attachments…")
        let attachmentsRoot = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Messages/Attachments")
        guard FileManager.default.fileExists(atPath: attachmentsRoot.path) else {
            return []
        }

        return FileScannerHelpers.enumerateFiles(
            in: attachmentsRoot,
            categoryID: category.id,
            riskLevel: .review,
            excludePaths: settings.excludePaths,
            maxDepth: 8,
            progress: progress
        ) { _, values in
            Int64(values.fileSize ?? 0) > 500_000
        }.sorted { $0.sizeBytes > $1.sizeBytes }
    }
}

enum ScanAccessError: LocalizedError {
    case fullDiskAccessRequired

    var errorDescription: String? {
        switch self {
        case .fullDiskAccessRequired:
            return "Full Disk Access is required to scan this category. Enable it in System Settings → Privacy & Security."
        }
    }
}
