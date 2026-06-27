import Foundation

struct SimulatorScanner: CleanupScanner {
    let category = CleanupCategory.simulators

    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem] {
        guard XcodeAvailability.isInstalled else { return [] }

        progress.reportImmediate(progress: nil, message: "Scanning simulators…")
        let coreSimRoot = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer/CoreSimulator/Devices")
        guard FileManager.default.fileExists(atPath: coreSimRoot.path) else { return [] }

        var items: [ScannableItem] = []
        let devices = (try? FileManager.default.contentsOfDirectory(at: coreSimRoot, includingPropertiesForKeys: nil)) ?? []
        let total = devices.count

        for (index, deviceURL) in devices.enumerated() {
            let plistURL = deviceURL.appendingPathComponent("device.plist")
            var deviceName = deviceURL.lastPathComponent
            var isAvailable = true

            if let data = try? Data(contentsOf: plistURL),
               let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
                deviceName = plist["name"] as? String ?? deviceName
                if let state = plist["state"] as? Int, state != 1 {
                    isAvailable = false
                }
            }

            progress.report(
                progress: total > 0 ? Double(index) / Double(total) : nil,
                message: deviceName
            )

            let size = FileScannerHelpers.directorySize(at: deviceURL)
            guard size > 10 * 1_024 * 1_024 else { continue }

            items.append(ScannableItem(
                path: deviceURL.path,
                name: deviceName,
                sizeBytes: size,
                categoryID: category.id,
                riskLevel: .review,
                detail: isAvailable ? "Simulator device data" : "Unavailable simulator"
            ))
        }

        progress.report(progress: 1, message: "Found \(items.count) simulators")
        return items.sorted { $0.sizeBytes > $1.sizeBytes }
    }
}

extension SimulatorScanner {
    static func deleteUnavailableSimulators() throws -> String {
        try SubprocessRunner().runShell("xcrun simctl delete unavailable 2>/dev/null || true")
    }
}
