import Foundation

struct TimeMachineScanner: CleanupScanner {
    let category = CleanupCategory.timeMachineSnapshots
    private let runner = SubprocessRunner()

    func scan(settings: ScanSettings, progress: ScanProgressReporter) async throws -> [ScannableItem] {
        progress.reportImmediate(progress: nil, message: "Listing Time Machine snapshots…")
        let output: String
        do {
            output = try runner.run(executable: "/usr/bin/tmutil", arguments: ["listlocalsnapshots", "/"])
        } catch {
            return []
        }

        let lines = output.split(separator: "\n").map(String.init)
        var items: [ScannableItem] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.contains("com.apple.TimeMachine") else { continue }
            let snapshotName = trimmed
            items.append(ScannableItem(
                path: snapshotName,
                name: snapshotName,
                sizeBytes: 0,
                categoryID: category.id,
                riskLevel: .safe,
                detail: "Local Time Machine snapshot (size estimated after selection)"
            ))
        }
        progress.report(progress: 1, message: "Found \(items.count) snapshots")
        return items
    }
}

extension TimeMachineScanner {
    static func deleteSnapshot(_ name: String) throws {
        _ = try SubprocessRunner().run(
            executable: "/usr/bin/tmutil",
            arguments: ["deletelocalsnapshots", name.replacingOccurrences(of: "com.apple.TimeMachine.", with: "")]
        )
    }
}
