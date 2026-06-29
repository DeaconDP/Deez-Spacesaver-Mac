import Foundation
import CryptoKit

enum RiskLevel: String, Codable, CaseIterable, Comparable {
    case safe
    case review
    case caution

    var label: String {
        switch self {
        case .safe: return "Safe"
        case .review: return "Review"
        case .caution: return "Caution"
        }
    }

    private var sortRank: Int {
        switch self {
        case .safe: return 0
        case .review: return 1
        case .caution: return 2
        }
    }

    static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        lhs.sortRank < rhs.sortRank
    }
}

struct ScannableItem: Identifiable, Hashable, Codable {
    let id: UUID
    let path: String
    let name: String
    let sizeBytes: Int64
    let modifiedDate: Date?
    let categoryID: String
    let riskLevel: RiskLevel
    let detail: String?

    init(
        id: UUID? = nil,
        path: String,
        name: String? = nil,
        sizeBytes: Int64,
        modifiedDate: Date? = nil,
        categoryID: String,
        riskLevel: RiskLevel = .safe,
        detail: String? = nil
    ) {
        self.id = id ?? ScannableItem.stableID(for: path)
        self.path = path
        self.name = name ?? (path as NSString).lastPathComponent
        self.sizeBytes = sizeBytes
        self.modifiedDate = modifiedDate
        self.categoryID = categoryID
        self.riskLevel = riskLevel
        self.detail = detail
    }
}

extension ScannableItem {
    var sortableModifiedDate: Date {
        modifiedDate ?? .distantPast
    }

    static func stableID(for path: String) -> UUID {
        let digest = SHA256.hash(data: Data(path.utf8))
        let bytes = Array(digest.prefix(16))
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}

struct CategoryScanResult: Identifiable {
    let category: CleanupCategory
    var items: [ScannableItem]
    var scannedAt: Date
    var errorMessage: String?

    var id: String { category.id }
    var totalBytes: Int64 { items.reduce(0) { $0 + $1.sizeBytes } }
}

enum ScanStatus: Equatable {
    case idle
    case scanning(progress: Double?, message: String?)
    case completed
    case failed(String)
}
