import Foundation

struct GuidedScanner: CleanupScanner {
    let category: CleanupCategory

    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem] {
        progress.reportImmediate(progress: 1, message: "Ready")
        switch category.id {
        case CleanupCategory.iCloudOptimize.id:
            return [ScannableItem(
                path: "guided://icloud-optimize",
                name: "Optimize Mac Storage",
                sizeBytes: 0,
                categoryID: category.id,
                riskLevel: .safe,
                detail: "Opens System Settings to enable iCloud storage optimization."
            )]
        case CleanupCategory.systemRestart.id:
            return [ScannableItem(
                path: "guided://system-restart",
                name: "Restart Your Mac",
                sizeBytes: 0,
                categoryID: category.id,
                riskLevel: .safe,
                detail: "Restarting clears temporary swap and cache files (typically 5–15 GB)."
            )]
        default:
            return []
        }
    }
}

enum ScannerRegistry {
    static var all: [any CleanupScanner] {
        var scanners: [any CleanupScanner] = [
            TrashScanner(),
            DownloadsScanner(),
            LargeFilesScanner(),
            InstallersScanner(),
            IOSBackupScanner(),
            TimeMachineScanner(),
            CachesScanner(),
            BrowserCachesScanner(),
            LogsScanner(),
            MailAttachmentsScanner(),
            MessagesAttachmentsScanner(),
            GuidedScanner(category: .iCloudOptimize),
            GuidedScanner(category: .systemRestart)
        ]

        if XcodeAvailability.isInstalled {
            scanners.append(AppUninstallScanner())
            scanners.append(XcodeDerivedDataScanner())
            scanners.append(XcodeDeviceSupportScanner())
            scanners.append(XcodeArchivesScanner())
            scanners.append(SimulatorScanner())
            scanners.append(PackageManagerScanner())
        } else {
            scanners.append(AppUninstallScanner())
        }

        return scanners
    }
}
