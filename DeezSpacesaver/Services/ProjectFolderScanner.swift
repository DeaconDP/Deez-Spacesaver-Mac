import Foundation

struct ProjectFolderMeasurement: Sendable {
    let folderID: UUID
    let allocatedBytes: Int64?
    let availability: ProjectFolderAvailability
    let scannedAt: Date
}

struct ProjectFolderScanner: Sendable {
    typealias ProgressHandler = @Sendable (_ completed: Int, _ total: Int, _ folderName: String) -> Void

    func measure(
        folders: [ProjectFolder],
        progress: ProgressHandler? = nil
    ) async throws -> [ProjectFolderMeasurement] {
        try await Task.detached(priority: .userInitiated) {
            let fileManager = FileManager.default
            var measurements: [ProjectFolderMeasurement] = []

            for (index, folder) in folders.enumerated() {
                try Task.checkCancellation()
                progress?(index, folders.count, folder.name)

                let url = URL(fileURLWithPath: folder.path, isDirectory: true)
                var isDirectory = ObjCBool(false)
                let exists = fileManager.fileExists(atPath: folder.path, isDirectory: &isDirectory)
                let measurement: ProjectFolderMeasurement

                if !exists || !isDirectory.boolValue {
                    measurement = ProjectFolderMeasurement(
                        folderID: folder.id,
                        allocatedBytes: nil,
                        availability: .missing,
                        scannedAt: Date()
                    )
                } else if !fileManager.isReadableFile(atPath: folder.path) {
                    measurement = ProjectFolderMeasurement(
                        folderID: folder.id,
                        allocatedBytes: nil,
                        availability: .inaccessible,
                        scannedAt: Date()
                    )
                } else if let bytes = try Self.allocatedSize(of: url, fileManager: fileManager) {
                    measurement = ProjectFolderMeasurement(
                        folderID: folder.id,
                        allocatedBytes: bytes,
                        availability: .available,
                        scannedAt: Date()
                    )
                } else {
                    measurement = ProjectFolderMeasurement(
                        folderID: folder.id,
                        allocatedBytes: nil,
                        availability: .inaccessible,
                        scannedAt: Date()
                    )
                }

                measurements.append(measurement)
                progress?(index + 1, folders.count, folder.name)
            }

            return measurements
        }.value
    }

    private static func allocatedSize(of root: URL, fileManager: FileManager) throws -> Int64? {
        let keys: [URLResourceKey] = [
            .isRegularFileKey,
            .isSymbolicLinkKey,
            .totalFileAllocatedSizeKey,
            .fileAllocatedSizeKey,
            .fileSizeKey,
            .fileResourceIdentifierKey
        ]
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: keys,
            options: [],
            errorHandler: { _, _ in true }
        ) else {
            return nil
        }

        var total: Int64 = 0
        var seenFileIdentifiers = Set<AnyHashable>()
        for case let fileURL as URL in enumerator {
            try Task.checkCancellation()
            guard let values = try? fileURL.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true,
                  values.isSymbolicLink != true else {
                continue
            }
            if let identifier = values.fileResourceIdentifier as? AnyHashable,
               !seenFileIdentifiers.insert(identifier).inserted {
                continue
            }
            let bytes = values.totalFileAllocatedSize
                ?? values.fileAllocatedSize
                ?? values.fileSize
                ?? 0
            total += Int64(bytes)
        }
        return total
    }
}
