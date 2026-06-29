import Foundation

struct ScanSettings: Sendable {
    let largeFileThresholdBytes: Int64
    let downloadsMinAgeDays: Int
    let unusedAppsMinDays: Int
    let excludePaths: [String]

    static let `default` = ScanSettings(
        largeFileThresholdBytes: 500 * 1_024 * 1_024,
        downloadsMinAgeDays: 30,
        unusedAppsMinDays: 90,
        excludePaths: []
    )
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var largeFileThresholdMB: Int {
        didSet { UserDefaults.standard.set(largeFileThresholdMB, forKey: Keys.largeFileThresholdMB) }
    }

    @Published var downloadsMinAgeDays: Int {
        didSet { UserDefaults.standard.set(downloadsMinAgeDays, forKey: Keys.downloadsMinAgeDays) }
    }

    @Published var unusedAppsMinDays: Int {
        didSet { UserDefaults.standard.set(unusedAppsMinDays, forKey: Keys.unusedAppsMinDays) }
    }

    @Published var excludePaths: [String] {
        didSet { saveExcludePaths() }
    }

    @Published var hasSeenFDAOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasSeenFDAOnboarding, forKey: Keys.hasSeenFDAOnboarding) }
    }

    private enum Keys {
        static let largeFileThresholdMB = "largeFileThresholdMB"
        static let downloadsMinAgeDays = "downloadsMinAgeDays"
        static let unusedAppsMinDays = "unusedAppsMinDays"
        static let excludePaths = "excludePaths"
        static let hasSeenFDAOnboarding = "hasSeenFDAOnboarding"
    }

    private init() {
        let defaults = UserDefaults.standard
        largeFileThresholdMB = defaults.object(forKey: Keys.largeFileThresholdMB) as? Int ?? 500
        downloadsMinAgeDays = defaults.object(forKey: Keys.downloadsMinAgeDays) as? Int ?? 30
        unusedAppsMinDays = defaults.object(forKey: Keys.unusedAppsMinDays) as? Int ?? 90
        hasSeenFDAOnboarding = defaults.bool(forKey: Keys.hasSeenFDAOnboarding)
        excludePaths = Self.loadExcludePaths()
    }

    var largeFileThresholdBytes: Int64 {
        Int64(largeFileThresholdMB) * 1_024 * 1_024
    }

    var scanSettings: ScanSettings {
        ScanSettings(
            largeFileThresholdBytes: largeFileThresholdBytes,
            downloadsMinAgeDays: downloadsMinAgeDays,
            unusedAppsMinDays: unusedAppsMinDays,
            excludePaths: excludePaths
        )
    }

    private static func loadExcludePaths() -> [String] {
        guard let data = UserDefaults.standard.data(forKey: Keys.excludePaths),
              let paths = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return paths
    }

    private func saveExcludePaths() {
        if let data = try? JSONEncoder().encode(excludePaths) {
            UserDefaults.standard.set(data, forKey: Keys.excludePaths)
        }
    }

    func addExcludePath(_ path: String) {
        let normalized = (path as NSString).standardizingPath
        guard !excludePaths.contains(normalized) else { return }
        excludePaths.append(normalized)
    }

    func removeExcludePath(_ path: String) {
        excludePaths.removeAll { $0 == path }
    }
}
