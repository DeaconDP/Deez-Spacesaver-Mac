import Foundation

struct StorageService {
    func fetchDiskStats() -> DiskStats {
        let home = FileManager.default.homeDirectoryForCurrentUser
        guard let values = try? home.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey
        ]) else {
            return .empty
        }

        let total = Int64(values.volumeTotalCapacity ?? 0)
        let available: Int64
        if let important = values.volumeAvailableCapacityForImportantUsage {
            available = Int64(important)
        } else if let basic = values.volumeAvailableCapacity {
            available = Int64(basic)
        } else {
            available = 0
        }
        return DiskStats(totalBytes: total, availableBytes: available)
    }
}
