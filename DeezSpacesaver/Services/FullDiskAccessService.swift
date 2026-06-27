import AppKit
import Foundation

struct FullDiskAccessService {
    var appBundlePath: String {
        Bundle.main.bundleURL.path
    }

    func hasFullDiskAccess() -> Bool {
        Self.probeFullDiskAccess(fileManager: .default)
    }

    static func probeFullDiskAccess(
        fileManager: FileManager = .default,
        homeDirectory: URL? = nil
    ) -> Bool {
        let home = homeDirectory ?? fileManager.homeDirectoryForCurrentUser
        let probes = [
            home.appendingPathComponent("Library/Mail").path,
            home.appendingPathComponent("Library/Containers/com.apple.stocks").path
        ]
        return probes.contains { canListProtectedDirectory(at: $0, fileManager: fileManager) }
    }

    static func canListProtectedDirectory(at path: String, fileManager: FileManager = .default) -> Bool {
        var isDirectory = ObjCBool(false)
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return false
        }

        do {
            _ = try fileManager.contentsOfDirectory(atPath: path)
            return true
        } catch {
            return false
        }
    }

    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }

    func revealAppInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }

    func beginFullDiskAccessSetup() {
        openPrivacySettings()
        revealAppInFinder()
    }

    func relaunchApp() {
        let url = Bundle.main.bundleURL
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, _ in
            NSApp.terminate(nil)
        }
    }

    func openStorageSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.settings.Storage") {
            NSWorkspace.shared.open(url)
        }
    }

    func openICloudSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.systempreferences.AppleIDSettings") {
            NSWorkspace.shared.open(url)
        }
    }
}
