import Foundation

struct CleanupActionService {
    private let trashService = TrashService()

    func performCleanup(
        items: [ScannableItem],
        category: CleanupCategory
    ) async -> CleanupActionResult {
        guard !items.isEmpty else {
            return CleanupActionResult(succeeded: [], failed: [], message: "No items selected.")
        }

        if category.isGuidedOnly {
            return handleGuided(items: items, category: category)
        }

        if category.id == CleanupCategory.timeMachineSnapshots.id {
            return await deleteTimeMachineSnapshots(items)
        }

        if category.id == CleanupCategory.trash.id {
            return await emptyTrash(items: items)
        }

        if category.id == CleanupCategory.appUninstall.id {
            return await uninstallApps(items)
        }

        if category.id == CleanupCategory.simulators.id {
            return await deleteSimulatorItems(items)
        }

        let fileItems = items.filter { !$0.path.hasPrefix("guided://") && $0.path != "brew-cleanup" }
        let result = await trashService.moveToTrash(items: fileItems)
        var message = "Moved \(result.succeeded.count) item(s) to Trash."
        if !result.failed.isEmpty {
            message += " \(result.failed.count) failed."
        }
        return CleanupActionResult(
            succeeded: result.succeeded,
            failed: result.failed,
            message: message
        )
    }

    private func handleGuided(items: [ScannableItem], category: CleanupCategory) -> CleanupActionResult {
        let fda = FullDiskAccessService()
        if category.id == CleanupCategory.iCloudOptimize.id {
            fda.openICloudSettings()
            return CleanupActionResult(succeeded: items, failed: [], message: "Opened iCloud settings.")
        }
        if category.id == CleanupCategory.systemRestart.id {
            return CleanupActionResult(
                succeeded: items,
                failed: [],
                message: "Choose Apple menu → Restart to clear temporary system files."
            )
        }
        return CleanupActionResult(succeeded: [], failed: [], message: nil)
    }

    private func emptyTrash(items: [ScannableItem]) async -> CleanupActionResult {
        do {
            try trashService.emptyTrash()
            return CleanupActionResult(succeeded: items, failed: [], message: "Trash emptied successfully.")
        } catch {
            let result = await trashService.moveToTrash(items: items)
            if result.succeeded.isEmpty {
                return CleanupActionResult(succeeded: [], failed: result.failed, message: error.localizedDescription)
            }
            return CleanupActionResult(
                succeeded: result.succeeded,
                failed: result.failed,
                message: "Could not empty Trash automatically. Items remain in Trash — empty manually from Finder."
            )
        }
    }

    private func deleteTimeMachineSnapshots(_ items: [ScannableItem]) async -> CleanupActionResult {
        var succeeded: [ScannableItem] = []
        var failed: [(ScannableItem, String)] = []

        for item in items {
            do {
                let datePart = item.path.replacingOccurrences(of: "com.apple.TimeMachine.", with: "")
                try TimeMachineScanner.deleteSnapshot(datePart)
                succeeded.append(item)
            } catch {
                failed.append((item, error.localizedDescription))
            }
        }

        return CleanupActionResult(
            succeeded: succeeded,
            failed: failed,
            message: "Deleted \(succeeded.count) snapshot(s)."
        )
    }

    private func uninstallApps(_ items: [ScannableItem]) async -> CleanupActionResult {
        var allURLs: [ScannableItem] = []
        for item in items {
            let appURL = URL(fileURLWithPath: item.path)
            for related in AppUninstallScanner.relatedPaths(for: appURL) {
                allURLs.append(ScannableItem(
                    path: related.path,
                    sizeBytes: 0,
                    categoryID: item.categoryID,
                    riskLevel: item.riskLevel
                ))
            }
        }
        let unique = Dictionary(grouping: allURLs, by: \.path).compactMap { $0.value.first }
        let result = await trashService.moveToTrash(items: unique)
        return CleanupActionResult(
            succeeded: result.succeeded,
            failed: result.failed,
            message: "Moved \(result.succeeded.count) app-related item(s) to Trash."
        )
    }

    private func deleteSimulatorItems(_ items: [ScannableItem]) async -> CleanupActionResult {
        let result = await trashService.moveToTrash(items: items)
        return CleanupActionResult(
            succeeded: result.succeeded,
            failed: result.failed,
            message: "Removed \(result.succeeded.count) simulator data folder(s)."
        )
    }
}

struct CleanupActionResult {
    let succeeded: [ScannableItem]
    let failed: [(ScannableItem, String)]
    let message: String?
}
