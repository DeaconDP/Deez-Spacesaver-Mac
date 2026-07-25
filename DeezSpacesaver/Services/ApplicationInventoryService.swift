import AppKit
import Foundation

struct ApplicationInventoryService: Sendable {
    typealias ProgressHandler = @Sendable (_ completed: Int, _ total: Int, _ appName: String) -> Void

    let applicationsRoot: URL
    let currentApplicationPath: String

    init(
        applicationsRoot: URL = URL(fileURLWithPath: "/Applications", isDirectory: true),
        currentApplicationPath: String = Bundle.main.bundlePath
    ) {
        self.applicationsRoot = applicationsRoot
        self.currentApplicationPath = currentApplicationPath
    }

    func load(progress: ProgressHandler? = nil) async throws -> [InstalledApplication] {
        let runningBundleIdentifiers = Set(
            NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier)
        )

        return try await Task.detached(priority: .userInitiated) {
            let fileManager = FileManager.default
            let appURLs = Self.discoverApplications(
                under: applicationsRoot,
                fileManager: fileManager
            )
            var applications: [InstalledApplication] = []

            for (index, appURL) in appURLs.enumerated() {
                try Task.checkCancellation()
                let name = appURL.deletingPathExtension().lastPathComponent
                progress?(index, appURLs.count, name)

                let bundleIdentifier = AppUninstallScanner.bundleIdentifier(at: appURL)
                let availability = Self.removalAvailability(
                    for: appURL,
                    bundleIdentifier: bundleIdentifier,
                    applicationsRoot: applicationsRoot,
                    currentApplicationPath: currentApplicationPath,
                    runningBundleIdentifiers: runningBundleIdentifiers,
                    fileManager: fileManager
                )
                applications.append(InstalledApplication(
                    path: appURL.path,
                    name: name,
                    bundleIdentifier: bundleIdentifier,
                    sizeBytes: try Self.allocatedSize(of: appURL, fileManager: fileManager),
                    lastOpenedDate: AppUninstallScanner.lastUsedDate(for: appURL),
                    removalAvailability: availability
                ))
                progress?(index + 1, appURLs.count, name)
            }

            return applications.sorted {
                if $0.sizeBytes == $1.sizeBytes {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                return $0.sizeBytes > $1.sizeBytes
            }
        }.value
    }

    static func discoverApplications(
        under root: URL,
        fileManager: FileManager = .default
    ) -> [URL] {
        let keys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey]
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else {
            return []
        }

        var applications: [URL] = []
        for case let url as URL in enumerator {
            guard url.pathExtension.localizedCaseInsensitiveCompare("app") == .orderedSame else {
                continue
            }
            enumerator.skipDescendants()
            applications.append(url)
        }
        return applications
    }

    static func removalAvailability(
        for appURL: URL,
        bundleIdentifier: String?,
        applicationsRoot: URL,
        currentApplicationPath: String,
        runningBundleIdentifiers: Set<String>,
        fileManager: FileManager = .default
    ) -> ApplicationRemovalAvailability {
        guard SafetyGuard.isSafeApplicationBundle(appURL, under: applicationsRoot) else {
            return .unsafeLocation
        }
        if SafetyGuard.canonicalPath(appURL.path) == SafetyGuard.canonicalPath(currentApplicationPath) {
            return .currentApplication
        }
        if let bundleIdentifier, AppUninstallScanner.isProtectedBundleID(bundleIdentifier) {
            return .protectedSystemApplication
        }
        if let bundleIdentifier, runningBundleIdentifiers.contains(bundleIdentifier) {
            return .running
        }
        if !fileManager.isWritableFile(atPath: appURL.path) {
            return .notWritable
        }
        return .removable
    }

    private static func allocatedSize(of root: URL, fileManager: FileManager) throws -> Int64 {
        let keys: Set<URLResourceKey> = [
            .isRegularFileKey,
            .isSymbolicLinkKey,
            .totalFileAllocatedSizeKey,
            .fileAllocatedSizeKey,
            .fileSizeKey,
            .fileResourceIdentifierKey
        ]
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: Array(keys),
            options: [],
            errorHandler: { _, _ in true }
        ) else {
            return 0
        }

        var total: Int64 = 0
        var seenFileIdentifiers = Set<AnyHashable>()
        for case let fileURL as URL in enumerator {
            try Task.checkCancellation()
            guard let values = try? fileURL.resourceValues(forKeys: keys),
                  values.isRegularFile == true,
                  values.isSymbolicLink != true else {
                continue
            }
            if let identifier = values.fileResourceIdentifier as? AnyHashable,
               !seenFileIdentifiers.insert(identifier).inserted {
                continue
            }
            total += Int64(
                values.totalFileAllocatedSize
                    ?? values.fileAllocatedSize
                    ?? values.fileSize
                    ?? 0
            )
        }
        return total
    }
}
