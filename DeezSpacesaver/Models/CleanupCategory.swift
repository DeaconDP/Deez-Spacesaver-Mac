import Foundation

enum CategoryGroup: String, CaseIterable, Identifiable {
    case quickWins = "Quick Wins"
    case apple = "Apple"
    case developer = "Developer"
    case system = "System"
    case guided = "Guided"

    var id: String { rawValue }
}

struct CleanupCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let group: CategoryGroup
    let systemImage: String
    let requiresFullDiskAccess: Bool
    let defaultRiskLevel: RiskLevel
    let isGuidedOnly: Bool

    static let trash = CleanupCategory(
        id: "trash",
        name: "Empty Trash",
        description: "Items already in Trash waiting to be permanently removed.",
        group: .quickWins,
        systemImage: "trash",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .safe,
        isGuidedOnly: false
    )

    static let downloads = CleanupCategory(
        id: "downloads",
        name: "Downloads",
        description: "Large or old files in your Downloads folder.",
        group: .quickWins,
        systemImage: "arrow.down.circle",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .review,
        isGuidedOnly: false
    )

    static let largeFiles = CleanupCategory(
        id: "largeFiles",
        name: "Large Files",
        description: "Files over your size threshold in common locations.",
        group: .quickWins,
        systemImage: "doc.fill.badge.ellipsis",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .review,
        isGuidedOnly: false
    )

    static let iosBackups = CleanupCategory(
        id: "iosBackups",
        name: "iOS Backups",
        description: "Old iPhone and iPad backup folders.",
        group: .apple,
        systemImage: "iphone",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .review,
        isGuidedOnly: false
    )

    static let timeMachineSnapshots = CleanupCategory(
        id: "timeMachineSnapshots",
        name: "Time Machine Snapshots",
        description: "Local Time Machine snapshots on your startup disk.",
        group: .system,
        systemImage: "clock.arrow.circlepath",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .safe,
        isGuidedOnly: false
    )

    static let userCaches = CleanupCategory(
        id: "userCaches",
        name: "App Caches",
        description: "Regeneratable cache files in ~/Library/Caches.",
        group: .system,
        systemImage: "memorychip",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .safe,
        isGuidedOnly: false
    )

    static let browserCaches = CleanupCategory(
        id: "browserCaches",
        name: "Browser Caches",
        description: "Safari, Chrome, Firefox, and Edge cache data.",
        group: .system,
        systemImage: "globe",
        requiresFullDiskAccess: true,
        defaultRiskLevel: .safe,
        isGuidedOnly: false
    )

    static let installers = CleanupCategory(
        id: "installers",
        name: "Installer Artifacts",
        description: "Leftover .dmg, .pkg, and .iso files.",
        group: .quickWins,
        systemImage: "shippingbox",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .review,
        isGuidedOnly: false
    )

    static let logs = CleanupCategory(
        id: "logs",
        name: "Log Files",
        description: "Application and diagnostic logs.",
        group: .system,
        systemImage: "doc.text",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .safe,
        isGuidedOnly: false
    )

    static let appUninstall = CleanupCategory(
        id: "appUninstall",
        name: "Unused Apps",
        description: "Applications and leftover support files.",
        group: .quickWins,
        systemImage: "app.badge.minus",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .caution,
        isGuidedOnly: false
    )

    static let xcodeDerivedData = CleanupCategory(
        id: "xcodeDerivedData",
        name: "Xcode Derived Data",
        description: "Build artifacts regenerated on next compile.",
        group: .developer,
        systemImage: "hammer",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .safe,
        isGuidedOnly: false
    )

    static let xcodeDeviceSupport = CleanupCategory(
        id: "xcodeDeviceSupport",
        name: "iOS Device Support",
        description: "Old device debugging symbols from Xcode.",
        group: .developer,
        systemImage: "iphone.gen3",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .review,
        isGuidedOnly: false
    )

    static let xcodeArchives = CleanupCategory(
        id: "xcodeArchives",
        name: "Xcode Archives",
        description: "Saved .xcarchive build exports.",
        group: .developer,
        systemImage: "archivebox",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .caution,
        isGuidedOnly: false
    )

    static let simulators = CleanupCategory(
        id: "simulators",
        name: "iOS Simulators",
        description: "Unavailable simulator devices and data.",
        group: .developer,
        systemImage: "display",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .review,
        isGuidedOnly: false
    )

    static let packageManagers = CleanupCategory(
        id: "packageManagers",
        name: "Package Manager Caches",
        description: "Homebrew, npm, pip, and Docker cache data.",
        group: .developer,
        systemImage: "cube.box",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .safe,
        isGuidedOnly: false
    )

    static let mailAttachments = CleanupCategory(
        id: "mailAttachments",
        name: "Mail Attachments",
        description: "Downloaded Mail attachment caches.",
        group: .apple,
        systemImage: "envelope",
        requiresFullDiskAccess: true,
        defaultRiskLevel: .review,
        isGuidedOnly: false
    )

    static let messagesAttachments = CleanupCategory(
        id: "messagesAttachments",
        name: "Messages Attachments",
        description: "Photos, videos, and files from Messages.",
        group: .apple,
        systemImage: "message",
        requiresFullDiskAccess: true,
        defaultRiskLevel: .review,
        isGuidedOnly: false
    )

    static let iCloudOptimize = CleanupCategory(
        id: "iCloudOptimize",
        name: "iCloud Optimize Storage",
        description: "Open System Settings to enable iCloud storage optimization.",
        group: .guided,
        systemImage: "icloud",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .safe,
        isGuidedOnly: true
    )

    static let systemRestart = CleanupCategory(
        id: "systemRestart",
        name: "System Maintenance",
        description: "Restart recommendations for swap and temp file recovery.",
        group: .guided,
        systemImage: "arrow.clockwise",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .safe,
        isGuidedOnly: true
    )

    static let all: [CleanupCategory] = [
        .trash, .downloads, .largeFiles, .installers, .appUninstall,
        .iosBackups, .mailAttachments, .messagesAttachments, .iCloudOptimize,
        .userCaches, .browserCaches, .logs, .timeMachineSnapshots, .systemRestart,
        .xcodeDerivedData, .xcodeDeviceSupport, .xcodeArchives, .simulators, .packageManagers
    ]

    static func byID(_ id: String) -> CleanupCategory? {
        all.first { $0.id == id }
    }
}
