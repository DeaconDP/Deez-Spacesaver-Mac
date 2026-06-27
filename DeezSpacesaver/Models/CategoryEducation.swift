import Foundation

struct CategoryEducation {
    let overview: String
    let whatItFinds: String
    let onCleanup: String
    let considerations: String?

    static func content(for category: CleanupCategory) -> CategoryEducation {
        contentByID[category.id] ?? CategoryEducation(
            overview: category.description,
            whatItFinds: "Varies by category.",
            onCleanup: "Move selected items to Trash.",
            considerations: nil
        )
    }

    private static let contentByID: [String: CategoryEducation] = [
        CleanupCategory.trash.id: CategoryEducation(
            overview: "Files you already moved to Trash still occupy disk space until Trash is emptied. This category lists everything waiting in Trash so you can permanently remove it.",
            whatItFinds: "Contents of ~/.Trash",
            onCleanup: "Runs Finder \"Empty Trash\" (AppleScript). Falls back to trashing individual items if empty fails.",
            considerations: "Requires Apple Events permission. Space is not freed until Trash is actually emptied."
        ),
        CleanupCategory.downloads.id: CategoryEducation(
            overview: "Downloads often accumulate large installers, archives, and files you forgot about. This scan surfaces candidates based on age and size.",
            whatItFinds: "~/Downloads (depth 3): files older than your min-age setting (default 30 days), files ≥ large-file threshold (default 500 MB), or installer extensions (.dmg, .zip, .pkg, .iso, .mpkg)",
            onCleanup: "Move selected files to Trash.",
            considerations: "Review before deleting — you may still need some files. Thresholds adjustable in Settings."
        ),
        CleanupCategory.largeFiles.id: CategoryEducation(
            overview: "Big files in common folders are often the fastest way to reclaim space. This scan finds files above your size threshold.",
            whatItFinds: "~/Documents, ~/Desktop, ~/Downloads, ~/Movies, ~/Pictures (depth 6), files ≥ threshold (default 500 MB), sorted largest first",
            onCleanup: "Move to Trash.",
            considerations: "Does not scan external drives or custom locations. Add exclude paths in Settings if needed."
        ),
        CleanupCategory.installers.id: CategoryEducation(
            overview: "DMG, PKG, and ISO files are safe to remove after you've finished installing — they are just the delivery package.",
            whatItFinds: ".dmg, .pkg, .mpkg, .iso in ~/Downloads, ~/Desktop, and home root",
            onCleanup: "Move to Trash.",
            considerations: "Only delete installers for apps you have already installed and no longer need to reinstall."
        ),
        CleanupCategory.appUninstall.id: CategoryEducation(
            overview: "Removing apps you no longer use frees the app bundle plus related support files scattered in Library folders.",
            whatItFinds: ".app bundles in /Applications, plus related paths: Application Support, Containers, Preferences, and Caches for each app",
            onCleanup: "Moves app bundle and all related support paths to Trash.",
            considerations: "Deleting an app removes its data. Reinstalling may not restore settings. Review each app carefully."
        ),
        CleanupCategory.iosBackups.id: CategoryEducation(
            overview: "Each iPhone/iPad backup can be many gigabytes. Old device backups are often the largest reclaimable Apple data on a Mac.",
            whatItFinds: "Folders in ~/Library/Application Support/MobileSync/Backup, labeled by device name from backup metadata",
            onCleanup: "Move backup folder to Trash.",
            considerations: "Deleting a backup means you cannot restore that device to that point in time. Keep backups for devices you still use."
        ),
        CleanupCategory.mailAttachments.id: CategoryEducation(
            overview: "Mail caches downloaded attachments on disk. Clearing the cache does not delete mail from your account — attachments re-download when you open messages.",
            whatItFinds: "Files >500 KB under ~/Library/Mail in Attachments paths",
            onCleanup: "Move to Trash.",
            considerations: "Requires Full Disk Access. Attachments will re-download when opened in Mail."
        ),
        CleanupCategory.messagesAttachments.id: CategoryEducation(
            overview: "Messages stores photos, videos, and files locally. Clearing cached attachments frees space; media may re-download from iCloud when viewed.",
            whatItFinds: "Files >500 KB in ~/Library/Messages/Attachments (depth 8)",
            onCleanup: "Move to Trash.",
            considerations: "Requires Full Disk Access. Media may re-download when you open conversations."
        ),
        CleanupCategory.iCloudOptimize.id: CategoryEducation(
            overview: "macOS can keep recent files on your Mac and store older files in iCloud, freeing local disk space automatically.",
            whatItFinds: "No file scan — opens System Settings",
            onCleanup: "Opens Apple ID → iCloud settings.",
            considerations: "Requires iCloud Drive enabled. Does not delete files — moves infrequently used files to cloud."
        ),
        CleanupCategory.xcodeDerivedData.id: CategoryEducation(
            overview: "Derived Data is Xcode's build cache — intermediate files from compiling your projects. It is completely regenerated on the next build.",
            whatItFinds: "Subfolders of ~/Library/Developer/Xcode/DerivedData",
            onCleanup: "Move to Trash.",
            considerations: "Next build will be slower while cache rebuilds. Safe for active projects."
        ),
        CleanupCategory.xcodeDeviceSupport.id: CategoryEducation(
            overview: "Xcode downloads device symbols for each iOS version you debug against. Old versions for devices you no longer use can be removed.",
            whatItFinds: "Folders in ~/Library/Developer/Xcode/iOS DeviceSupport (named by iOS version)",
            onCleanup: "Move to Trash.",
            considerations: "If you connect an old device again, Xcode will re-download symbols (one-time delay)."
        ),
        CleanupCategory.xcodeArchives.id: CategoryEducation(
            overview: "Archives are saved .xcarchive bundles used for App Store submission and distribution. They can be very large.",
            whatItFinds: ".xcarchive bundles under ~/Library/Developer/Xcode/Archives",
            onCleanup: "Move to Trash.",
            considerations: "Archives are your only local copy of signed builds. Verify you have copies elsewhere before deleting."
        ),
        CleanupCategory.simulators.id: CategoryEducation(
            overview: "Simulator runtimes and device data accumulate over time. Unavailable simulators are safe to remove.",
            whatItFinds: "Device folders in ~/Library/Developer/CoreSimulator/Devices (>10 MB, unavailable state preferred)",
            onCleanup: "Move device data folders to Trash.",
            considerations: "Simulators can be re-downloaded from Xcode. Unavailable devices are orphaned runtimes."
        ),
        CleanupCategory.packageManagers.id: CategoryEducation(
            overview: "Homebrew, npm, pip, Yarn, pnpm, and Docker cache downloaded packages locally. Caches speed up installs but can grow large.",
            whatItFinds: "Cache dirs: Homebrew, npm _cacache, pnpm store, Yarn, pip, Docker (each ≥5 MB). Also shows estimated Homebrew reclaim via dry-run",
            onCleanup: "Move cache folders to Trash.",
            considerations: "Packages re-download on next install/update. The virtual \"brew cleanup\" estimate item is informational only — not actionable."
        ),
        CleanupCategory.userCaches.id: CategoryEducation(
            overview: "Apps store temporary data in ~/Library/Caches to load faster. These files are regeneratable and safe to clear.",
            whatItFinds: "Top-level subfolders of ~/Library/Caches",
            onCleanup: "Move cache folder to Trash.",
            considerations: "Apps may be slower on first launch after clearing. No personal documents are affected."
        ),
        CleanupCategory.browserCaches.id: CategoryEducation(
            overview: "Browsers cache pages, images, and assets locally. Clearing cache frees space but pages reload from the network.",
            whatItFinds: "Safari, Chrome, Firefox, and Edge cache directories (each ≥1 MB)",
            onCleanup: "Move to Trash.",
            considerations: "Requires Full Disk Access. Websites reload slower until cache rebuilds. Saved passwords and bookmarks are not affected."
        ),
        CleanupCategory.logs.id: CategoryEducation(
            overview: "Apps and macOS write diagnostic logs that grow over time. Old logs are rarely needed unless you are troubleshooting.",
            whatItFinds: "Files >100 KB in ~/Library/Logs and ~/Library/Logs/DiagnosticReports (depth 4)",
            onCleanup: "Move to Trash.",
            considerations: "If Apple Support asked you to keep logs for a bug report, skip those files."
        ),
        CleanupCategory.timeMachineSnapshots.id: CategoryEducation(
            overview: "macOS creates local Time Machine snapshots on your startup disk between full backups. These can consume significant space.",
            whatItFinds: "Local snapshots listed by tmutil listlocalsnapshots",
            onCleanup: "Permanent deletion via tmutil deletelocalsnapshots — not moved to Trash.",
            considerations: "Snapshots provide recent restore points. macOS recreates snapshots over time. Size shown as 0 until deletion."
        ),
        CleanupCategory.systemRestart.id: CategoryEducation(
            overview: "macOS swap files and temporary system caches accumulate during long uptime. A restart clears them and often recovers 5–15 GB.",
            whatItFinds: "No file scan — informational",
            onCleanup: "Shows restart instructions.",
            considerations: "Save open work first. Choose Apple menu → Restart."
        )
    ]
}

extension CleanupCategory {
    var education: CategoryEducation {
        CategoryEducation.content(for: self)
    }
}
