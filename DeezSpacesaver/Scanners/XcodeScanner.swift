import Foundation

struct XcodeDerivedDataScanner: CleanupScanner {
    let category = CleanupCategory.xcodeDerivedData

    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem] {
        return scanXcodeFolder(
            relativePath: "Developer/Xcode/DerivedData",
            categoryID: category.id,
            riskLevel: .safe,
            detail: "Xcode build cache — regenerated on next build",
            progress: progress
        )
    }
}

struct XcodeDeviceSupportScanner: CleanupScanner {
    let category = CleanupCategory.xcodeDeviceSupport

    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem] {
        let root = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport")
        guard FileManager.default.fileExists(atPath: root.path) else { return [] }

        progress.reportImmediate(progress: nil, message: "Scanning device support…")
        let contents = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
        var items: [ScannableItem] = []
        let total = contents.count

        for (index, url) in contents.enumerated() {
            progress.report(
                progress: total > 0 ? Double(index) / Double(total) : nil,
                message: url.lastPathComponent
            )
            let size = FileScannerHelpers.directorySize(at: url)
            items.append(ScannableItem(
                path: url.path,
                sizeBytes: size,
                categoryID: category.id,
                riskLevel: .review,
                detail: "Device symbols for iOS \(url.lastPathComponent)"
            ))
        }
        progress.report(progress: 1, message: "Found \(items.count) device support folders")
        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }
}

struct XcodeArchivesScanner: CleanupScanner {
    let category = CleanupCategory.xcodeArchives

    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem] {
        progress.reportImmediate(progress: nil, message: "Scanning Xcode archives…")
        let root = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer/Xcode/Archives")
        guard FileManager.default.fileExists(atPath: root.path) else { return [] }

        var items: [ScannableItem] = []
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var archiveCount = 0
        for case let url as URL in enumerator {
            guard url.pathExtension == "xcarchive" else { continue }
            archiveCount += 1
            progress.report(progress: nil, message: url.lastPathComponent)
            let size = FileScannerHelpers.directorySize(at: url)
            items.append(ScannableItem(
                path: url.path,
                sizeBytes: size,
                categoryID: category.id,
                riskLevel: .caution,
                detail: "App Store archive — verify before deleting"
            ))
        }
        progress.report(progress: 1, message: "Found \(archiveCount) archives")
        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }
}

private func scanXcodeFolder(
    relativePath: String,
    categoryID: String,
    riskLevel: RiskLevel,
    detail: String,
    progress: ScanProgressReporter
) -> [ScannableItem] {
    let root = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/\(relativePath)")
    guard FileManager.default.fileExists(atPath: root.path) else { return [] }

    progress.reportImmediate(progress: nil, message: "Scanning \(root.lastPathComponent)…")
    let contents = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
    var items: [ScannableItem] = []
    let total = contents.count

    for (index, url) in contents.enumerated() {
        progress.report(
            progress: total > 0 ? Double(index) / Double(total) : nil,
            message: url.lastPathComponent
        )
        let size = FileScannerHelpers.directorySize(at: url)
        guard size > 0 else { continue }
        items.append(ScannableItem(
            path: url.path,
            sizeBytes: size,
            categoryID: categoryID,
            riskLevel: riskLevel,
            detail: detail
        ))
    }
    progress.report(progress: 1, message: "Found \(items.count) items")
    return items.sorted { $0.sizeBytes > $1.sizeBytes }
}

struct XcodeAvailability {
    static var isInstalled: Bool {
        FileManager.default.fileExists(atPath: "/Applications/Xcode.app")
            || FileManager.default.fileExists(atPath: "/Library/Developer/CommandLineTools")
    }
}
