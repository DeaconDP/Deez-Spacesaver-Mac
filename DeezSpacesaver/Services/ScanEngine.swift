import Foundation

@MainActor
final class ScanEngine: ObservableObject {
    @Published private(set) var results: [String: CategoryScanResult] = [:]
    @Published private(set) var statuses: [String: ScanStatus] = [:]
    @Published private(set) var isScanningAll = false
    @Published private(set) var scanAllProgress: Double?
    @Published private(set) var scanAllMessage: String?

    private let scanners: [any CleanupScanner]
    private var activeTasks: [String: Task<Void, Never>] = [:]
    private var scanAllCategoryIDs: [String] = []

    init(scanners: [any CleanupScanner] = ScannerRegistry.all) {
        self.scanners = scanners
        for scanner in scanners {
            statuses[scanner.category.id] = .idle
        }
    }

    var totalReclaimableBytes: Int64 {
        results.values.reduce(0) { $0 + $1.totalBytes }
    }

    func scanner(for categoryID: String) -> (any CleanupScanner)? {
        scanners.first { $0.category.id == categoryID }
    }

    func scan(categoryID: String, settings: AppSettings = .shared) {
        guard let scanner = scanner(for: categoryID) else { return }
        activeTasks[categoryID]?.cancel()

        statuses[categoryID] = .scanning(progress: nil, message: "Starting…")
        let reporter = ScanProgressReporter { [weak self] progress, message in
            Task { @MainActor in
                self?.statuses[categoryID] = .scanning(progress: progress, message: message)
                self?.updateScanAllAggregate()
            }
        }

        activeTasks[categoryID] = Task {
            do {
                let items = try await scanner.scan(settings: settings.scanSettings, progress: reporter)
                guard !Task.isCancelled else { return }
                results[categoryID] = CategoryScanResult(
                    category: scanner.category,
                    items: items.sorted { $0.sizeBytes > $1.sizeBytes },
                    scannedAt: Date(),
                    errorMessage: nil
                )
                statuses[categoryID] = .completed
                updateScanAllAggregate()
            } catch {
                guard !Task.isCancelled else { return }
                results[categoryID] = CategoryScanResult(
                    category: scanner.category,
                    items: [],
                    scannedAt: Date(),
                    errorMessage: error.localizedDescription
                )
                statuses[categoryID] = .failed(error.localizedDescription)
                updateScanAllAggregate()
            }
        }
    }

    func scanAll(settings: AppSettings = .shared) {
        isScanningAll = true
        scanAllProgress = 0
        scanAllMessage = "Starting scan…"
        let scannable = scanners.filter { !$0.category.isGuidedOnly }
        scanAllCategoryIDs = scannable.map(\.category.id)

        for scanner in scannable {
            scan(categoryID: scanner.category.id, settings: settings)
        }

        Task {
            while scannable.contains(where: { statuses[$0.category.id]?.isActiveScan == true }) {
                updateScanAllAggregate()
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
            isScanningAll = false
            scanAllProgress = nil
            scanAllMessage = nil
            scanAllCategoryIDs = []
            CyberpunkHaptics.levelChange()
        }
    }

    func cancelScan(categoryID: String) {
        activeTasks[categoryID]?.cancel()
        activeTasks[categoryID] = nil
        statuses[categoryID] = .idle
        updateScanAllAggregate()
    }

    func clearResult(categoryID: String) {
        results.removeValue(forKey: categoryID)
        statuses[categoryID] = .idle
    }

    private func updateScanAllAggregate() {
        guard isScanningAll, !scanAllCategoryIDs.isEmpty else { return }

        let total = scanAllCategoryIDs.count
        var completed = 0
        var inProgressFraction: Double = 0

        for id in scanAllCategoryIDs {
            switch statuses[id] {
            case .completed, .failed:
                completed += 1
            case .scanning(let progress, _):
                inProgressFraction += progress ?? 0
            default:
                break
            }
        }

        let activeScans = scanAllCategoryIDs.filter {
            if case .scanning = statuses[$0] { return true }
            return false
        }.count

        let aggregate = (Double(completed) + inProgressFraction) / Double(total)
        scanAllProgress = min(aggregate, 1)
        scanAllMessage = "Scanning \(min(completed + (activeScans > 0 ? 1 : 0), total)) of \(total) categories…"
    }
}

private extension ScanStatus {
    var isActiveScan: Bool {
        if case .scanning = self { return true }
        return false
    }
}
