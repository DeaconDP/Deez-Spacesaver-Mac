import SwiftUI

struct ScanResultsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedIDs: Set<UUID> = []
    @State private var showConfirmLargeBatch = false
    @State private var pendingCleanup: [ScannableItem] = []
    @State private var sortOrder = [KeyPathComparator(\ScannableItem.sizeBytes, order: .reverse)]

    private var category: CleanupCategory? {
        guard let id = appState.selectedCategoryID else { return nil }
        return CleanupCategory.byID(id)
    }

    private var result: CategoryScanResult? {
        guard let id = appState.selectedCategoryID else { return nil }
        return appState.scanEngine.results[id]
    }

    private var scanStatus: ScanStatus? {
        guard let id = appState.selectedCategoryID else { return nil }
        return appState.scanEngine.statuses[id]
    }

    private var bannerTransition: AnyTransition {
        .move(edge: .top).combined(with: .opacity)
    }

    private var contentTransition: AnyTransition {
        .opacity.combined(with: .offset(y: 6))
    }

    private var contentStateKey: String {
        guard let category else { return "empty-selection" }
        if category.isGuidedOnly { return "guided-\(category.id)" }
        if isScanning { return "scanning-\(category.id)" }
        if let result, !result.items.isEmpty { return "results-\(category.id)-\(result.items.count)" }
        return "empty-results-\(category.id)"
    }

    var body: some View {
        Group {
            if let category {
                content(for: category)
                    .transition(contentTransition)
            } else {
                emptySelection
                    .transition(.opacity)
            }
        }
        .animation(
            CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
            value: appState.selectedCategoryID
        )
        .onChange(of: appState.selectedCategoryID) { _, _ in
            selectedIDs.removeAll()
            sortOrder = [KeyPathComparator(\ScannableItem.sizeBytes, order: .reverse)]
        }
        .background(CyberpunkColors.bgPrimary)
        .alert("Confirm Large Cleanup", isPresented: $showConfirmLargeBatch) {
            Button("Cancel", role: .cancel) {}
            Button("Move to Trash", role: .destructive) {
                CyberpunkHaptics.generic()
                Task { await performCleanup(pendingCleanup, category: category!) }
            }
        } message: {
            Text("You are about to move \(pendingCleanup.count) items (\(ByteFormatting.string(for: pendingCleanup.reduce(0) { $0 + $1.sizeBytes }))) to Trash.")
        }
    }

    private var emptySelection: some View {
        VStack(spacing: 12) {
            Image(systemName: "externaldrive")
                .font(.system(size: 48))
                .foregroundStyle(CyberpunkColors.textMuted)
            Text("Select a category to scan")
                .font(CyberpunkTypography.display(16))
                .foregroundStyle(CyberpunkColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func content(for category: CleanupCategory) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(for: category)

            if let banner = appState.feedbackBanner {
                CyberpunkFeedbackBanner(banner: banner) {
                    appState.dismissFeedback()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .transition(bannerTransition)
            }

            if category.requiresFullDiskAccess && !appState.hasFullDiskAccess {
                fdaBanner
                    .transition(bannerTransition)
            }

            if let error = result?.errorMessage {
                errorBanner(error)
                    .transition(bannerTransition)
            }

            if isScanning, let result, !result.items.isEmpty {
                let (progress, message) = scanProgressValues()
                ScanProgressView(progress: progress, message: message)
                    .padding(.vertical, 12)
                    .transition(bannerTransition)
            }

            Group {
                if category.isGuidedOnly {
                    guidedContent(for: category)
                } else if let result, !result.items.isEmpty {
                    resultsTable(result.items, category: category)
                } else {
                    emptyResults(for: category)
                }
            }
            .transition(contentTransition)
        }
        .animation(
            CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
            value: contentStateKey
        )
        .animation(
            CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
            value: appState.hasFullDiskAccess
        )
        .animation(
            CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
            value: appState.feedbackBanner
        )
    }

    private func header(for category: CleanupCategory) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(CyberpunkTypography.display(18))
                    .foregroundStyle(CyberpunkColors.textPrimary)
                Text(category.description)
                    .font(CyberpunkTypography.body(12))
                    .foregroundStyle(CyberpunkColors.textMuted)
            }
            Spacer()
            Button {
                appState.scanSelectedCategory()
            } label: {
                CyberpunkLoadingLabel(
                    isLoading: isScanning,
                    title: isScanning ? "Scanning…" : "Scan"
                )
            }
            .buttonStyle(CyberpunkPrimaryButton())
            .disabled(isScanning)
        }
        .padding(16)
        .background(CyberpunkColors.bgSecondary)
    }

    private var isScanning: Bool {
        guard let id = appState.selectedCategoryID else { return false }
        if case .scanning = appState.scanEngine.statuses[id] { return true }
        return false
    }

    private func scanProgressValues() -> (Double?, String) {
        guard let status = scanStatus else { return (nil, "Scanning…") }
        if case .scanning(let progress, let message) = status {
            return (progress, message ?? "Scanning…")
        }
        return (nil, "Scanning…")
    }

    private func resultsTable(_ items: [ScannableItem], category: CleanupCategory) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button(selectedIDs.count == items.count ? "Deselect All" : "Select All") {
                    withAnimation(CyberpunkAnimation.apply(CyberpunkAnimation.quick, reduceMotion: reduceMotion)) {
                        if selectedIDs.count == items.count {
                            selectedIDs.removeAll()
                        } else {
                            selectedIDs = Set(items.map(\.id))
                        }
                    }
                }
                .buttonStyle(CyberpunkSecondaryButton())

                Spacer()

                let selected = items.filter { selectedIDs.contains($0.id) }
                let total = selected.reduce(0) { $0 + $1.sizeBytes }

                Button {
                    requestCleanup(selected, category: category)
                } label: {
                    cleanupButtonLabel(for: category, total: total)
                }
                .buttonStyle(CyberpunkPrimaryButton())
                .disabled(selected.isEmpty || appState.isCleaningUp)
            }
            .padding(12)
            .animation(
                CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
                value: selectedIDs.count
            )

            Table(items, selection: $selectedIDs, sortOrder: $sortOrder) {
                TableColumn("") { item in
                    selectionIcon(for: item)
                }
                .width(30)

                TableColumn("Risk", value: \.riskLevel) { item in
                    RiskBadge(level: item.riskLevel)
                }
                .width(72)

                TableColumn("Name", value: \.name) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Button(item.name) {
                            FileRevealService.reveal(path: item.path)
                        }
                        .buttonStyle(.link)
                        .foregroundStyle(CyberpunkColors.textPrimary)
                        if let detail = item.detail {
                            Text(detail)
                                .font(CyberpunkTypography.body(10))
                                .foregroundStyle(CyberpunkColors.textMuted)
                        }
                    }
                }

                TableColumn("Size", value: \.sizeBytes) { item in
                    Text(ByteFormatting.string(for: item.sizeBytes))
                        .font(CyberpunkTypography.mono(12))
                        .foregroundStyle(ByteFormatting.color(for: item.sizeBytes))
                }
                .width(90)

                TableColumn("Modified", value: \.sortableModifiedDate) { item in
                    if let date = item.modifiedDate {
                        Text(date, style: .date)
                            .font(CyberpunkTypography.body(11))
                            .foregroundStyle(CyberpunkColors.textSecondary)
                    }
                }
                .width(100)

                TableColumn("Path", value: \.path) { item in
                    Text(item.path)
                        .font(CyberpunkTypography.mono(10))
                        .foregroundStyle(CyberpunkColors.textMuted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .tableStyle(.inset(alternatesRowBackgrounds: true))
            .id("\(category.id)-\(result?.scannedAt.timeIntervalSince1970 ?? 0)-\(items.count)")
        }
    }

    @ViewBuilder
    private func selectionIcon(for item: ScannableItem) -> some View {
        let isSelected = selectedIDs.contains(item.id)
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .foregroundStyle(isSelected ? CyberpunkColors.accent : CyberpunkColors.textMuted)
            .symbolEffect(.bounce, value: isSelected)
            .animation(
                CyberpunkAnimation.apply(CyberpunkAnimation.quick, reduceMotion: reduceMotion),
                value: isSelected
            )
    }

    @ViewBuilder
    private func cleanupButtonLabel(for category: CleanupCategory, total: Int64) -> some View {
        if category.id == CleanupCategory.trash.id {
            CyberpunkLoadingLabel(
                isLoading: appState.isCleaningUp,
                title: appState.isCleaningUp ? "Emptying Trash…" : "Empty Trash"
            )
        } else {
            CyberpunkLoadingLabel(
                isLoading: appState.isCleaningUp,
                title: appState.isCleaningUp
                    ? "Moving to Trash…"
                    : "Move to Trash (\(ByteFormatting.string(for: total)))"
            )
            .contentTransition(.numericText())
            .animation(
                CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
                value: total
            )
        }
    }

    private func guidedContent(for category: CleanupCategory) -> some View {
        VStack(spacing: 16) {
            Spacer()
            if category.id == CleanupCategory.iCloudOptimize.id {
                Text("Enable Optimize Mac Storage in iCloud settings to keep recent files local and store older files in iCloud.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(CyberpunkColors.textSecondary)
                    .padding(.horizontal, 40)
                Button("Open iCloud Settings") {
                    FullDiskAccessService().openICloudSettings()
                }
                .buttonStyle(CyberpunkPrimaryButton())
            } else if category.id == CleanupCategory.systemRestart.id {
                Text("Restarting your Mac clears temporary swap files and system caches, often recovering 5–15 GB.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(CyberpunkColors.textSecondary)
                    .padding(.horizontal, 40)
                Text("Choose Apple menu → Restart")
                    .font(CyberpunkTypography.display(14))
                    .foregroundStyle(CyberpunkColors.accent)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func emptyResults(for category: CleanupCategory) -> some View {
        VStack(spacing: 12) {
            if isScanning {
                let (progress, message) = scanProgressValues()
                ScanProgressView(progress: progress, message: message)
                    .transition(.opacity.combined(with: .offset(y: 6)))
            } else {
                Image(systemName: category.systemImage)
                    .font(.system(size: 36))
                    .foregroundStyle(CyberpunkColors.textMuted)
                Text("No items found. Tap Scan to check this category.")
                    .foregroundStyle(CyberpunkColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fdaBanner: some View {
        HStack {
            Text("Full Disk Access required for this category.")
                .foregroundStyle(CyberpunkColors.accentWarn)
            Button("Add Full Disk Access") { appState.beginFullDiskAccessSetup() }
                .buttonStyle(CyberpunkSecondaryButton())
        }
        .padding(12)
        .background(CyberpunkColors.accentWarn.opacity(0.1))
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Text(message)
                .font(CyberpunkTypography.body(12))
                .foregroundStyle(CyberpunkColors.accentSecondary)
            Spacer()
            Button("Retry Scan") {
                appState.scanSelectedCategory()
            }
            .buttonStyle(CyberpunkSecondaryButton())
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CyberpunkColors.accentSecondaryDim)
    }

    private func requestCleanup(_ items: [ScannableItem], category: CleanupCategory) {
        let totalBytes = items.reduce(0) { $0 + $1.sizeBytes }
        if SafetyGuard.requiresLargeBatchConfirmation(itemCount: items.count, totalBytes: totalBytes) {
            pendingCleanup = items
            showConfirmLargeBatch = true
        } else {
            Task { await performCleanup(items, category: category) }
        }
    }

    private func performCleanup(_ items: [ScannableItem], category: CleanupCategory) async {
        await appState.cleanupSelected(items: items, category: category)
        selectedIDs.removeAll()
    }
}
