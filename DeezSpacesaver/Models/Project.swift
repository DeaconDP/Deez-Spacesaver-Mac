import Foundation

struct ProjectFolderTag: Codable, Hashable, Identifiable, Sendable {
    let name: String

    var id: String { name.lowercased() }

    init(_ name: String) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static let working = ProjectFolderTag("Working")
    static let backup = ProjectFolderTag("Backup")
    static let broken = ProjectFolderTag("Broken")
    static let junk = ProjectFolderTag("Junk")
    static let experiment = ProjectFolderTag("Experiment")

    static let defaults: [ProjectFolderTag] = [
        .working, .backup, .broken, .junk, .experiment
    ]
}

enum ProjectFolderAvailability: String, Codable, Sendable {
    case available
    case missing
    case inaccessible
}

enum ProjectFolderSortField: String, CaseIterable, Identifiable, Sendable {
    case size
    case tag
    case name
    case location

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    func sorted(_ folders: [ProjectFolder], ascending: Bool) -> [ProjectFolder] {
        folders.sorted { lhs, rhs in
            if self == .size, (lhs.allocatedBytes == nil) != (rhs.allocatedBytes == nil) {
                return lhs.allocatedBytes != nil
            }

            let comparison = primaryComparison(lhs, rhs)
            if comparison != .orderedSame {
                return ascending ? comparison == .orderedAscending : comparison == .orderedDescending
            }

            let nameComparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
            if nameComparison != .orderedSame {
                return nameComparison == .orderedAscending
            }

            let pathComparison = lhs.path.localizedCaseInsensitiveCompare(rhs.path)
            if pathComparison != .orderedSame {
                return pathComparison == .orderedAscending
            }

            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    private func primaryComparison(_ lhs: ProjectFolder, _ rhs: ProjectFolder) -> ComparisonResult {
        switch self {
        case .size:
            let left = lhs.allocatedBytes ?? 0
            let right = rhs.allocatedBytes ?? 0
            if left == right { return .orderedSame }
            return left < right ? .orderedAscending : .orderedDescending
        case .tag:
            return lhs.tag.name.localizedCaseInsensitiveCompare(rhs.tag.name)
        case .name:
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name)
        case .location:
            return lhs.path.localizedCaseInsensitiveCompare(rhs.path)
        }
    }
}

struct ProjectFolder: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var path: String
    var tag: ProjectFolderTag
    var allocatedBytes: Int64?
    var lastScannedAt: Date?
    var availability: ProjectFolderAvailability

    init(
        id: UUID = UUID(),
        path: String,
        tag: ProjectFolderTag = .working,
        allocatedBytes: Int64? = nil,
        lastScannedAt: Date? = nil,
        availability: ProjectFolderAvailability = .available
    ) {
        self.id = id
        self.path = (path as NSString).standardizingPath
        self.tag = tag
        self.allocatedBytes = allocatedBytes
        self.lastScannedAt = lastScannedAt
        self.availability = availability
    }

    var name: String {
        URL(fileURLWithPath: path).lastPathComponent
    }
}

struct ManagedProject: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    let createdAt: Date
    var folders: [ProjectFolder]

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        folders: [ProjectFolder] = []
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
        self.folders = folders
    }

    var totalAllocatedBytes: Int64 {
        folders.reduce(0) { $0 + ($1.allocatedBytes ?? 0) }
    }

    var lastScannedAt: Date? {
        folders.compactMap(\.lastScannedAt).max()
    }
}
