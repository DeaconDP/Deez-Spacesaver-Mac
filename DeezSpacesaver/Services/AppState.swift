import AppKit
import Foundation
import SwiftUI

enum SidebarSelection: Hashable {
    case category(String)
    case settings
}

@MainActor
final class AppState: ObservableObject {
    @Published var diskStats: DiskStats = .empty
    @Published var sidebarSelection: SidebarSelection?

    var selectedCategoryID: String? {
        guard case .category(let id) = sidebarSelection else { return nil }
        return id
    }
    @Published var showOnboarding = false
    @Published var feedbackBanner: FeedbackBanner?
    @Published var isCleaningUp = false
    @Published var isRefreshingDiskStats = false
    @Published var isCheckingFDA = false
    @Published private(set) var hasFullDiskAccess = false

    let scanEngine = ScanEngine()
    let settings = AppSettings.shared
    private let storageService = StorageService()
    private let cleanupService = CleanupActionService()
    private let fdaService = FullDiskAccessService()
    private var didBecomeActiveObserver: NSObjectProtocol?
    private var bannerDismissTask: Task<Void, Never>?

    var appBundlePath: String { fdaService.appBundlePath }

    init() {
        refreshFullDiskAccess()
        refreshDiskStats()
        if !settings.hasSeenFDAOnboarding {
            showOnboarding = true
        }
        didBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshFullDiskAccess()
            }
        }
    }

    deinit {
        if let didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(didBecomeActiveObserver)
        }
    }

    func refreshDiskStats() {
        diskStats = storageService.fetchDiskStats()
    }

    func refreshDiskStatsAsync() async {
        isRefreshingDiskStats = true
        defer { isRefreshingDiskStats = false }
        try? await Task.sleep(nanoseconds: 150_000_000)
        refreshDiskStats()
    }

    func selectCategory(_ category: CleanupCategory) {
        sidebarSelection = .category(category.id)
        if category.requiresFullDiskAccess && !hasFullDiskAccess {
            showOnboarding = true
        }
    }

    func selectSettings() {
        sidebarSelection = .settings
    }

    func dismissOnboarding(markSeen: Bool) {
        if markSeen { settings.hasSeenFDAOnboarding = true }
        showOnboarding = false
    }

    func refreshFullDiskAccess() {
        hasFullDiskAccess = fdaService.hasFullDiskAccess()
    }

    func checkFullDiskAccessAsync() async {
        isCheckingFDA = true
        defer { isCheckingFDA = false }
        try? await Task.sleep(nanoseconds: 200_000_000)
        refreshFullDiskAccess()
    }

    func openFullDiskAccessSettings() {
        fdaService.openPrivacySettings()
    }

    func beginFullDiskAccessSetup() {
        fdaService.beginFullDiskAccessSetup()
    }

    func revealAppInFinder() {
        fdaService.revealAppInFinder()
    }

    func relaunchApp() {
        fdaService.relaunchApp()
    }

    func scanSelectedCategory() {
        guard let id = selectedCategoryID else { return }
        scanEngine.scan(categoryID: id, settings: settings)
    }

    func scanAll() {
        scanEngine.scanAll(settings: settings)
    }

    func showFeedback(_ banner: FeedbackBanner, autoDismissAfter seconds: TimeInterval = 4) {
        bannerDismissTask?.cancel()
        feedbackBanner = banner
        bannerDismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            feedbackBanner = nil
        }
    }

    func dismissFeedback() {
        bannerDismissTask?.cancel()
        feedbackBanner = nil
    }

    func cleanupSelected(items: [ScannableItem], category: CleanupCategory) async {
        let totalBytes = items.reduce(0) { $0 + $1.sizeBytes }
        if SafetyGuard.requiresLargeBatchConfirmation(itemCount: items.count, totalBytes: totalBytes) {
            // Confirmation handled in view before calling this
        }

        isCleaningUp = true
        defer {
            isCleaningUp = false
            refreshDiskStats()
        }

        let result = await cleanupService.performCleanup(items: items, category: category)
        if let id = selectedCategoryID {
            scanEngine.scan(categoryID: id, settings: settings)
        }

        let message = result.message ?? "Cleanup finished."
        let hasFailures = !result.failed.isEmpty
        showFeedback(FeedbackBanner(
            message: message,
            style: hasFailures ? .error : .success
        ))
        if hasFailures {
            CyberpunkHaptics.generic()
        } else {
            CyberpunkHaptics.levelChange()
        }
    }
}
