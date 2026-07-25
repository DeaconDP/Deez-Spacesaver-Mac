import AppKit
import Combine
import Foundation
import SwiftUI

enum SidebarSelection: Hashable {
    case category(String)
    case appManager
    case projects
    case project(UUID)
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
    var selectedProjectID: UUID? {
        guard case .project(let id) = sidebarSelection else { return nil }
        return id
    }
    @Published var showOnboarding = false
    @Published var feedbackBanner: FeedbackBanner?
    @Published var isCleaningUp = false
    @Published var isRefreshingDiskStats = false
    @Published var isCheckingFDA = false
    @Published private(set) var isScanningProject = false
    @Published private(set) var projectScanProgress: Double?
    @Published private(set) var projectScanMessage: String?
    @Published private(set) var projectRepositoryStatuses: [UUID: GitRepositoryStatus] = [:]
    @Published private(set) var isRefreshingProjectRepositoryStatuses = false
    @Published private(set) var isSuggestingFolders = false
    @Published private(set) var suggestionProgressMessage: String?
    @Published private(set) var projectSuggestions: [ProjectFolderSuggestion] = []
    @Published private(set) var installedApplications: [InstalledApplication] = []
    @Published private(set) var isLoadingApplications = false
    @Published private(set) var applicationInventoryProgress: Double?
    @Published private(set) var applicationInventoryMessage: String?
    @Published private(set) var hasLoadedApplicationInventory = false
    @Published private(set) var isRemovingApplications = false
    @Published private(set) var hasFullDiskAccess = false

    let scanEngine = ScanEngine()
    let projectStore = ProjectStore()
    let settings = AppSettings.shared
    private let storageService = StorageService()
    private let cleanupService = CleanupActionService()
    private let fdaService = FullDiskAccessService()
    private let projectFolderScanner = ProjectFolderScanner()
    private let gitRepositoryStatusService = GitRepositoryStatusService()
    private let projectSuggestionService = ProjectSuggestionService()
    private let applicationInventoryService = ApplicationInventoryService()
    private var didBecomeActiveObserver: NSObjectProtocol?
    private var bannerDismissTask: Task<Void, Never>?
    private var scanEngineCancellable: AnyCancellable?
    private var projectStoreCancellable: AnyCancellable?

    var appBundlePath: String { fdaService.appBundlePath }

    init() {
        scanEngineCancellable = scanEngine.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        projectStoreCancellable = projectStore.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        refreshFullDiskAccess()
        refreshDiskStats()
        if let error = projectStore.lastError {
            feedbackBanner = FeedbackBanner(message: error, style: .error)
        }
        if !settings.hasSeenFDAOnboarding {
            showOnboarding = true
        }
        didBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
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

    func selectAppManager() {
        sidebarSelection = .appManager
    }

    func selectProjects() {
        sidebarSelection = .projects
    }

    func selectProject(id: UUID) {
        sidebarSelection = .project(id)
    }

    func createProject(named name: String) {
        do {
            let project = try projectStore.createProject(named: name)
            sidebarSelection = .project(project.id)
            showFeedback(FeedbackBanner(message: "Project created.", style: .success))
        } catch {
            showFeedback(FeedbackBanner(message: error.localizedDescription, style: .error))
        }
    }

    func renameProject(id: UUID, to name: String) {
        do {
            try projectStore.renameProject(id: id, to: name)
            showFeedback(FeedbackBanner(message: "Project renamed.", style: .success))
        } catch {
            showFeedback(FeedbackBanner(message: error.localizedDescription, style: .error))
        }
    }

    func deleteProject(id: UUID) {
        do {
            let folderIDs = Set(projectStore.project(id: id)?.folders.map(\.id) ?? [])
            try projectStore.deleteProject(id: id)
            projectRepositoryStatuses = projectRepositoryStatuses.filter {
                !folderIDs.contains($0.key)
            }
            sidebarSelection = .projects
            projectSuggestions = []
            showFeedback(FeedbackBanner(message: "Project removed.", style: .success))
        } catch {
            showFeedback(FeedbackBanner(message: error.localizedDescription, style: .error))
        }
    }

    func addFolder(path: String, tag: ProjectFolderTag, to projectID: UUID) {
        do {
            try projectStore.addFolder(path: path, tag: tag, to: projectID)
            showFeedback(FeedbackBanner(message: "Folder added to project.", style: .success))
        } catch {
            showFeedback(FeedbackBanner(message: error.localizedDescription, style: .error))
        }
    }

    func removeFolder(id folderID: UUID, from projectID: UUID) {
        do {
            try projectStore.removeFolder(id: folderID, from: projectID)
            projectRepositoryStatuses.removeValue(forKey: folderID)
            showFeedback(FeedbackBanner(message: "Folder removed from project.", style: .success))
        } catch {
            showFeedback(FeedbackBanner(message: error.localizedDescription, style: .error))
        }
    }

    func setTag(_ tag: ProjectFolderTag, for folderID: UUID, in projectID: UUID) {
        do {
            try projectStore.setTag(tag, for: folderID, in: projectID)
            showFeedback(FeedbackBanner(message: "Folder tag updated.", style: .success))
        } catch {
            showFeedback(FeedbackBanner(message: error.localizedDescription, style: .error))
        }
    }

    func setProjectSearchRoots(_ paths: [String]) {
        do {
            try projectStore.setSearchRoots(paths)
        } catch {
            showFeedback(FeedbackBanner(message: error.localizedDescription, style: .error))
        }
    }

    func refreshProjectSizes(projectID: UUID) async {
        guard !isScanningProject, let project = projectStore.project(id: projectID) else { return }
        guard !project.folders.isEmpty else {
            showFeedback(FeedbackBanner(message: "Add a folder before refreshing sizes.", style: .info))
            return
        }

        isScanningProject = true
        projectScanProgress = 0
        projectScanMessage = "Starting folder scan…"
        defer {
            isScanningProject = false
            projectScanProgress = nil
            projectScanMessage = nil
        }

        do {
            let measurements = try await projectFolderScanner.measure(
                folders: project.folders
            ) { [weak self] completed, total, folderName in
                Task { @MainActor [weak self] in
                    self?.projectScanProgress = total > 0 ? Double(completed) / Double(total) : nil
                    self?.projectScanMessage = "Measuring \(folderName)…"
                }
            }
            for measurement in measurements {
                try projectStore.updateFolderMeasurement(
                    folderID: measurement.folderID,
                    projectID: projectID,
                    allocatedBytes: measurement.allocatedBytes,
                    availability: measurement.availability,
                    scannedAt: measurement.scannedAt
                )
            }
            showFeedback(FeedbackBanner(message: "Folder sizes refreshed.", style: .success))
        } catch is CancellationError {
            showFeedback(FeedbackBanner(message: "Folder scan cancelled.", style: .info))
        } catch {
            showFeedback(FeedbackBanner(message: error.localizedDescription, style: .error))
        }
    }

    func refreshProjectRepositoryStatuses(
        projectID: UUID,
        reportsCompletion: Bool = true
    ) async {
        guard !isRefreshingProjectRepositoryStatuses,
              let project = projectStore.project(id: projectID) else {
            return
        }
        guard !project.folders.isEmpty else {
            if reportsCompletion {
                showFeedback(FeedbackBanner(
                    message: "Add a folder before refreshing Git status.",
                    style: .info
                ))
            }
            return
        }

        isRefreshingProjectRepositoryStatuses = true
        defer { isRefreshingProjectRepositoryStatuses = false }

        do {
            let statuses = try await gitRepositoryStatusService.inspect(folders: project.folders)
            let folderIDs = Set(project.folders.map(\.id))
            projectRepositoryStatuses = projectRepositoryStatuses.filter {
                !folderIDs.contains($0.key)
            }
            projectRepositoryStatuses.merge(statuses) { _, refreshed in refreshed }
            if reportsCompletion {
                showFeedback(FeedbackBanner(
                    message: "Git & GitHub statuses refreshed.",
                    style: .success
                ))
            }
        } catch is CancellationError {
            if reportsCompletion {
                showFeedback(FeedbackBanner(
                    message: "Git status refresh cancelled.",
                    style: .info
                ))
            }
        } catch {
            if reportsCompletion {
                showFeedback(FeedbackBanner(message: error.localizedDescription, style: .error))
            }
        }
    }

    func findProjectSuggestions(projectID: UUID) async {
        guard !isSuggestingFolders, let project = projectStore.project(id: projectID) else { return }
        guard !projectStore.searchRoots.isEmpty else {
            showFeedback(FeedbackBanner(message: "Choose at least one search location.", style: .info))
            return
        }

        isSuggestingFolders = true
        projectSuggestions = []
        suggestionProgressMessage = "Starting suggestion scan…"
        defer {
            isSuggestingFolders = false
            suggestionProgressMessage = nil
        }

        do {
            projectSuggestions = try await projectSuggestionService.suggest(
                projectName: project.name,
                roots: projectStore.searchRoots,
                associatedPaths: project.folders.map(\.path)
            ) { [weak self] inspected, folderName in
                Task { @MainActor [weak self] in
                    self?.suggestionProgressMessage = "Checked \(inspected) folders · \(folderName)"
                }
            }
            let message = projectSuggestions.isEmpty
                ? "No likely related folders found."
                : "Found \(projectSuggestions.count) possible project folders."
            showFeedback(FeedbackBanner(message: message, style: .success))
        } catch is CancellationError {
            showFeedback(FeedbackBanner(message: "Suggestion scan cancelled.", style: .info))
        } catch {
            showFeedback(FeedbackBanner(message: error.localizedDescription, style: .error))
        }
    }

    func clearProjectSuggestions() {
        projectSuggestions = []
    }

    func refreshInstalledApplications() async {
        guard !isLoadingApplications else { return }

        isLoadingApplications = true
        applicationInventoryProgress = 0
        applicationInventoryMessage = "Finding installed apps…"
        defer {
            isLoadingApplications = false
            applicationInventoryProgress = nil
            applicationInventoryMessage = nil
        }

        do {
            installedApplications = try await applicationInventoryService.load {
                [weak self] completed, total, appName in
                Task { @MainActor [weak self] in
                    self?.applicationInventoryProgress = total > 0
                        ? Double(completed) / Double(total)
                        : nil
                    self?.applicationInventoryMessage = "Measuring \(appName)…"
                }
            }
            hasLoadedApplicationInventory = true
        } catch is CancellationError {
            showFeedback(FeedbackBanner(message: "App scan cancelled.", style: .info))
        } catch {
            hasLoadedApplicationInventory = true
            showFeedback(FeedbackBanner(message: error.localizedDescription, style: .error))
        }
    }

    func removeInstalledApplications(_ applications: [InstalledApplication]) async -> Set<UUID> {
        guard !isRemovingApplications, !applications.isEmpty else {
            return Set(applications.map(\.id))
        }

        isRemovingApplications = true
        defer {
            isRemovingApplications = false
            refreshDiskStats()
        }

        let result = await cleanupService.removeApplicationBundles(applications)
        let failedPaths = Set(result.failed.map { $0.0.path })
        let failedIDs = Set(applications.filter { failedPaths.contains($0.path) }.map(\.id))
        await refreshInstalledApplications()

        var message = result.message ?? "App removal finished."
        if let firstFailure = result.failed.first {
            message += " \(firstFailure.0.name): \(firstFailure.1)"
        }
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
        return failedIDs
    }

    func addSuggestedFolders(paths: [String], tag: ProjectFolderTag, to projectID: UUID) {
        var added = 0
        var failures: [String] = []
        for path in paths {
            do {
                try projectStore.addFolder(path: path, tag: tag, to: projectID)
                added += 1
            } catch {
                failures.append(URL(fileURLWithPath: path).lastPathComponent)
            }
        }
        projectSuggestions.removeAll { paths.contains($0.path) }

        if failures.isEmpty {
            showFeedback(FeedbackBanner(
                message: "Added \(added) suggested folder\(added == 1 ? "" : "s").",
                style: .success
            ))
        } else {
            showFeedback(FeedbackBanner(
                message: "Added \(added) folders. Could not add: \(failures.joined(separator: ", ")).",
                style: .error
            ))
        }
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
