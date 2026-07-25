import AppKit
import Foundation

protocol TrashServicing {
    func moveToTrash(items: [ScannableItem]) async -> (
        succeeded: [ScannableItem],
        failed: [(ScannableItem, String)]
    )
    func emptyTrash() throws
}

struct TrashService: TrashServicing {
    private let fileManager = FileManager.default

    func moveToTrash(items: [ScannableItem]) async -> (succeeded: [ScannableItem], failed: [(ScannableItem, String)]) {
        var succeeded: [ScannableItem] = []
        var failed: [(ScannableItem, String)] = []

        for item in items {
            let url = URL(fileURLWithPath: item.path)
            do {
                var resultingURL: NSURL?
                try fileManager.trashItem(at: url, resultingItemURL: &resultingURL)
                succeeded.append(item)
            } catch {
                failed.append((item, error.localizedDescription))
            }
        }
        return (succeeded, failed)
    }

    func emptyTrash() throws {
        let script = """
        tell application "Finder" to empty trash
        """
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            if let error {
                throw NSError(domain: "DeezSpacesaver", code: 1, userInfo: error as? [String: Any])
            }
        }
    }
}
