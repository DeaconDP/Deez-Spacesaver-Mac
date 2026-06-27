import Foundation

enum RiskLevel: String, Codable, CaseIterable {
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
        id: UUID = UUID(),
        path: String,
        name: String? = nil,
        sizeBytes: Int64,
        modifiedDate: Date? = nil,
        categoryID: String,
        riskLevel: RiskLevel = .safe,
        detail: String? = nil
    ) {
        self.id = id
        self.path = path
        self.name = name ?? (path as NSString).lastPathComponent
        self.sizeBytes = sizeBytes
        self.modifiedDate = modifiedDate
        self.categoryID = categoryID
        self.riskLevel = riskLevel
        self.detail = detail
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
