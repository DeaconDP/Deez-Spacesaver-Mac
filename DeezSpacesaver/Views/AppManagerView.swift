import AppKit
import SwiftUI

struct AppManagerView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.detailWidth) private var detailWidth
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedIDs: Set<UUID> = []
    @State private var pendingApplications: [InstalledApplication] = []
    @State private var showRemovalConfirmation = false
    @State private var sortOrder = [
        KeyPathComparator(\InstalledApplication.sizeBytes, order: .reverse)
    ]

    private var sortedApplications: [InstalledApplication] {
        appState.installedApplications.sorted(using: sortOrder)
    }

    private var selectedApplications: [InstalledApplication] {
        sortedApplications.filter { selectedIDs.contains($0.id) && $0.isRemovable }
    }

    private var removableApplications: [InstalledApplication] {
        sortedApplications.filter(\.isRemovable)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if let banner = appState.feedbackBanner {
                CyberpunkFeedbackBanner(banner: banner) {
                    appState.dismissFeedback()
                }
                .padding(.horizontal, AppLayout.edge)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if appState.isLoadingApplications {
                ScanProgressView(
                    progress: appState.applicationInventoryProgress,
                    message: appState.applicationInventoryMessage ?? "Scanning Applications…",
                    label: "Application inventory progress"
                )
                .padding(AppLayout.edge)
                .accessibilityValue("Busy")
            }

            if appState.installedApplications.isEmpty {
                emptyState
            } else {
                inventory
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CyberpunkColors.bgPrimary)
        .animation(
            CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
            value: appState.feedbackBanner
        )
        .task {
            if !appState.hasLoadedApplicationInventory {
                await appState.refreshInstalledApplications()
            }
        }
        .onChange(of: appState.installedApplications) { _, applications in
            let removableIDs = Set(applications.filter(\.isRemovable).map(\.id))
            selectedIDs.formIntersection(removableIDs)
        }
        .onChange(of: selectedIDs) { _, selection in
            let removableIDs = Set(appState.installedApplications.filter(\.isRemovable).map(\.id))
            let validSelection = selection.intersection(removableIDs)
            if validSelection != selection {
                selectedIDs = validSelection
            }
        }
        .alert("Move Apps to Trash?", isPresented: $showRemovalConfirmation) {
            Button("Cancel", role: .cancel) {
                pendingApplications = []
            }
            Button("Move to Trash", role: .destructive) {
                let applications = pendingApplications
                pendingApplications = []
                Task {
                    selectedIDs = await appState.removeInstalledApplications(applications)
                }
            }
        } message: {
            Text(removalConfirmationText)
        }
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 16) {
                headerIdentity
                Spacer(minLength: 12)
                refreshButton
            }
            VStack(alignment: .leading, spacing: 12) {
                headerIdentity
                refreshButton
            }
        }
        .padding(AppLayout.edge)
        .background(CyberpunkColors.bgSecondary)
    }

    private var headerIdentity: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("App Manager")
                .font(CyberpunkTypography.display(22))
                .foregroundStyle(CyberpunkColors.textPrimary)
            Text("Review installed apps by size and move selected app bundles to Trash.")
                .font(CyberpunkTypography.body(12))
                .foregroundStyle(CyberpunkColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if appState.hasLoadedApplicationInventory {
                Text("\(appState.installedApplications.count) apps · \(ByteFormatting.string(for: appState.installedApplications.reduce(0) { $0 + $1.sizeBytes }))")
                    .font(CyberpunkTypography.mono(10))
                    .foregroundStyle(CyberpunkColors.textMuted)
            }
        }
    }

    private var refreshButton: some View {
        Button {
            Task { await appState.refreshInstalledApplications() }
        } label: {
            CyberpunkLoadingLabel(
                isLoading: appState.isLoadingApplications,
                title: appState.isLoadingApplications ? "Refreshing…" : "Refresh"
            )
        }
        .buttonStyle(CyberpunkSecondaryButton())
        .disabled(appState.isLoadingApplications || appState.isRemovingApplications)
        .accessibilityHint("Scans the Applications folder again")
    }

    private var inventory: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    selectAllButton
                    Spacer(minLength: 8)
                    removeButton
                }
                VStack(alignment: .leading, spacing: 8) {
                    selectAllButton
                    removeButton
                }
            }
            .padding(12)

            applicationsTable
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var selectAllButton: some View {
        let allSelected = !removableApplications.isEmpty
            && Set(removableApplications.map(\.id)).isSubset(of: selectedIDs)
        return Button(allSelected ? "Deselect All" : "Select Removable") {
            withAnimation(CyberpunkAnimation.apply(CyberpunkAnimation.quick, reduceMotion: reduceMotion)) {
                selectedIDs = allSelected ? [] : Set(removableApplications.map(\.id))
            }
        }
        .buttonStyle(CyberpunkSecondaryButton())
        .disabled(appState.isRemovingApplications || removableApplications.isEmpty)
    }

    private var removeButton: some View {
        let totalBytes = selectedApplications.reduce(0) { $0 + $1.sizeBytes }
        let compact = detailWidth < ResponsiveLayout.compactDetailWidth
        let idleTitle = compact
            ? "Trash (\(ByteFormatting.string(for: totalBytes)))"
            : "Move to Trash (\(ByteFormatting.string(for: totalBytes)))"

        return Button {
            pendingApplications = selectedApplications
            showRemovalConfirmation = true
        } label: {
            CyberpunkLoadingLabel(
                isLoading: appState.isRemovingApplications,
                title: appState.isRemovingApplications ? "Moving to Trash…" : idleTitle
            )
        }
        .buttonStyle(CyberpunkPrimaryButton())
        .disabled(
            selectedApplications.isEmpty
                || appState.isRemovingApplications
                || appState.isLoadingApplications
        )
        .accessibilityValue(appState.isRemovingApplications ? "Busy" : "\(selectedApplications.count) selected")
    }

    private var applicationsTable: some View {
        let showPath = ResponsiveLayout.showsPathColumn(width: detailWidth)

        return Table(sortedApplications, selection: $selectedIDs, sortOrder: $sortOrder) {
            TableColumn("") { application in
                Button {
                    toggleSelection(application)
                } label: {
                    Image(systemName: selectedIDs.contains(application.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(
                            application.isRemovable
                                ? (selectedIDs.contains(application.id) ? CyberpunkColors.accent : CyberpunkColors.textMuted)
                                : CyberpunkColors.borderSubtle
                        )
                }
                .buttonStyle(.plain)
                .disabled(!application.isRemovable || appState.isRemovingApplications)
                .help(application.removalAvailability.reason ?? "Select \(application.name)")
            }
            .width(30)

            TableColumn("Name", value: \.name) { application in
                HStack(spacing: 9) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: application.path))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Button(application.name) {
                            FileRevealService.reveal(path: application.path)
                        }
                        .buttonStyle(.link)
                        .foregroundStyle(CyberpunkColors.textPrimary)
                        .lineLimit(1)

                        if let reason = application.removalAvailability.reason {
                            Text(reason)
                                .font(CyberpunkTypography.body(9))
                                .foregroundStyle(CyberpunkColors.accentWarn)
                                .lineLimit(1)
                        } else if !showPath {
                            Text(application.path)
                                .font(CyberpunkTypography.mono(9))
                                .foregroundStyle(CyberpunkColors.textMuted)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }
            }

            TableColumn("Size", value: \.sizeBytes) { application in
                Text(ByteFormatting.string(for: application.sizeBytes))
                    .font(CyberpunkTypography.mono(12).weight(.semibold))
                    .foregroundStyle(ByteFormatting.color(for: application.sizeBytes))
                    .lineLimit(1)
            }
            .width(min: 78, ideal: 96)

            TableColumn("Last Opened", value: \.sortableLastOpenedDate) { application in
                if let date = application.lastOpenedDate {
                    Text(date, style: .date)
                        .font(CyberpunkTypography.body(11))
                        .foregroundStyle(CyberpunkColors.textSecondary)
                } else {
                    Text("Not available")
                        .font(CyberpunkTypography.body(10))
                        .foregroundStyle(CyberpunkColors.textMuted)
                }
            }
            .width(min: 94, ideal: 112)

            if showPath {
                TableColumn("Path", value: \.path) { application in
                    Text(application.path)
                        .font(CyberpunkTypography.mono(10))
                        .foregroundStyle(CyberpunkColors.textMuted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .id(showPath)
        .accessibilityValue(appState.isRemovingApplications ? "Busy" : "Ready")
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            if !appState.isLoadingApplications {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(CyberpunkColors.textMuted)
                Text("No applications found")
                    .font(CyberpunkTypography.display(16))
                    .foregroundStyle(CyberpunkColors.textSecondary)
                Text("Refresh to scan the Applications folder again.")
                    .font(CyberpunkTypography.body(12))
                    .foregroundStyle(CyberpunkColors.textMuted)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var removalConfirmationText: String {
        let names = pendingApplications.prefix(5).map(\.name).joined(separator: ", ")
        let remaining = max(0, pendingApplications.count - 5)
        let suffix = remaining > 0 ? ", and \(remaining) more" : ""
        return "Move \(names)\(suffix) to Trash? App settings and user data will remain on this Mac."
    }

    private func toggleSelection(_ application: InstalledApplication) {
        guard application.isRemovable else { return }
        if selectedIDs.contains(application.id) {
            selectedIDs.remove(application.id)
        } else {
            selectedIDs.insert(application.id)
        }
    }
}
