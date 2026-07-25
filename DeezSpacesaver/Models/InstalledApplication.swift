import Foundation

enum ApplicationRemovalAvailability: Hashable, Sendable {
    case removable
    case currentApplication
    case protectedSystemApplication
    case running
    case notWritable
    case unsafeLocation

    var reason: String? {
        switch self {
        case .removable:
            return nil
        case .currentApplication:
            return "DeezSpacesaver cannot remove itself"
        case .protectedSystemApplication:
            return "Protected macOS application"
        case .running:
            return "Quit this app before removing it"
        case .notWritable:
            return "Administrator permission may be required"
        case .unsafeLocation:
            return "App resolves outside the Applications folder"
        }
    }
}

struct InstalledApplication: Identifiable, Hashable, Sendable {
    let id: UUID
    let path: String
    let name: String
    let bundleIdentifier: String?
    let sizeBytes: Int64
    let lastOpenedDate: Date?
    let removalAvailability: ApplicationRemovalAvailability

    init(
        path: String,
        name: String,
        bundleIdentifier: String?,
        sizeBytes: Int64,
        lastOpenedDate: Date?,
        removalAvailability: ApplicationRemovalAvailability
    ) {
        self.id = ScannableItem.stableID(for: path)
        self.path = path
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.sizeBytes = sizeBytes
        self.lastOpenedDate = lastOpenedDate
        self.removalAvailability = removalAvailability
    }

    var isRemovable: Bool {
        removalAvailability == .removable
    }

    var sortableLastOpenedDate: Date {
        lastOpenedDate ?? .distantPast
    }
}
