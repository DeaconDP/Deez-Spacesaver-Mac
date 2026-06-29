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
        description: "Files already in Trash still use disk space until permanently removed.",
        group: .quickWins,
        systemImage: "trash",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .safe,
        isGuidedOnly: false
    )

    static let downloads = CleanupCategory(
        id: "downloads",
        name: "Downloads",
        description: "Large installers, archives, and forgotten files in your Downloads folder.",
        group: .quickWins,
        systemImage: "arrow.down.circle",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .review,
        isGuidedOnly: false
    )

    static let largeFiles = CleanupCategory(
        id: "largeFiles",
        name: "Large Files",
        description: "Big files above your size threshold in Documents, Desktop, and other common folders.",
        group: .quickWins,
        systemImage: "doc.fill.badge.ellipsis",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .review,
        isGuidedOnly: false
    )

    static let iosBackups = CleanupCategory(
        id: "iosBackups",
        name: "iOS Backups",
        description: "iPhone and iPad backups that can be many gigabytes each.",
        group: .apple,
        systemImage: "iphone",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .review,
        isGuidedOnly: false
    )

    static let timeMachineSnapshots = CleanupCategory(
        id: "timeMachineSnapshots",
        name: "Time Machine Snapshots",
        description: "Local restore points macOS keeps on your startup disk between full backups.",
        group: .system,
        systemImage: "clock.arrow.circlepath",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .safe,
        isGuidedOnly: false
    )

    static let userCaches = CleanupCategory(
        id: "userCaches",
        name: "App Caches",
        description: "Temporary cache files apps recreate automatically — safe to clear for space.",
        group: .system,
        systemImage: "memorychip",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .safe,
        isGuidedOnly: false
    )

    static let browserCaches = CleanupCategory(
        id: "browserCaches",
        name: "Browser Caches",
        description: "Cached pages and assets from Safari, Chrome, Firefox, and Edge.",
        group: .system,
        systemImage: "globe",
        requiresFullDiskAccess: true,
        defaultRiskLevel: .safe,
        isGuidedOnly: false
    )

    static let installers = CleanupCategory(
        id: "installers",
        name: "Installer Artifacts",
        description: "DMG, PKG, and ISO files left over after you've finished installing apps.",
        group: .quickWins,
        systemImage: "shippingbox",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .review,
        isGuidedOnly: false
    )

    static let logs = CleanupCategory(
        id: "logs",
        name: "Log Files",
        description: "Application and diagnostic logs that grow over time and are rarely needed.",
        group: .system,
        systemImage: "doc.text",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .safe,
        isGuidedOnly: false
    )

    static let appUninstall = CleanupCategory(
        id: "appUninstall",
        name: "Unused Apps",
        description: "Apps not opened recently, plus their support files scattered in Library folders.",
        group: .quickWins,
        systemImage: "app.badge.minus",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .caution,
        isGuidedOnly: false
    )

    static let xcodeDerivedData = CleanupCategory(
        id: "xcodeDerivedData",
        name: "Xcode Derived Data",
        description: "Xcode's build cache — intermediate compile files regenerated on the next build.",
        group: .developer,
        systemImage: "hammer",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .safe,
        isGuidedOnly: false
    )

    static let xcodeDeviceSupport = CleanupCategory(
        id: "xcodeDeviceSupport",
        name: "iOS Device Support",
        description: "Debugging symbols Xcode downloaded for iOS versions you no longer test against.",
        group: .developer,
        systemImage: "iphone.gen3",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .review,
        isGuidedOnly: false
    )

    static let xcodeArchives = CleanupCategory(
        id: "xcodeArchives",
        name: "Xcode Archives",
        description: "Saved release builds from Xcode for TestFlight and App Store submission.",
        group: .developer,
        systemImage: "archivebox",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .caution,
        isGuidedOnly: false
    )

    static let simulators = CleanupCategory(
        id: "simulators",
        name: "iOS Simulators",
        description: "Orphaned simulator runtimes and device data that can be re-downloaded from Xcode.",
        group: .developer,
        systemImage: "display",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .review,
        isGuidedOnly: false
    )

    static let packageManagers = CleanupCategory(
        id: "packageManagers",
        name: "Package Manager Caches",
        description: "Downloaded packages cached by Homebrew, npm, pip, Yarn, and Docker.",
        group: .developer,
        systemImage: "cube.box",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .safe,
        isGuidedOnly: false
    )

    static let mailAttachments = CleanupCategory(
        id: "mailAttachments",
        name: "Mail Attachments",
        description: "Attachment files Mail cached locally — they re-download when you open messages.",
        group: .apple,
        systemImage: "envelope",
        requiresFullDiskAccess: true,
        defaultRiskLevel: .review,
        isGuidedOnly: false
    )

    static let messagesAttachments = CleanupCategory(
        id: "messagesAttachments",
        name: "Messages Attachments",
        description: "Photos, videos, and files Messages stores locally that may re-download from iCloud.",
        group: .apple,
        systemImage: "message",
        requiresFullDiskAccess: true,
        defaultRiskLevel: .review,
        isGuidedOnly: false
    )

    static let iCloudOptimize = CleanupCategory(
        id: "iCloudOptimize",
        name: "iCloud Optimize Storage",
        description: "Store older files in iCloud and keep recent ones local to free disk space.",
        group: .guided,
        systemImage: "icloud",
        requiresFullDiskAccess: false,
        defaultRiskLevel: .safe,
        isGuidedOnly: true
    )

    static let systemRestart = CleanupCategory(
        id: "systemRestart",
        name: "System Maintenance",
        description: "Restarting clears swap files and temp caches, often recovering 5–15 GB.",
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
