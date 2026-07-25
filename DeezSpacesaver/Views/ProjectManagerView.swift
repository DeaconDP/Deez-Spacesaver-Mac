import AppKit
import SwiftUI

enum ProjectTagStyle {
    static func color(for tag: ProjectFolderTag) -> Color {
        switch tag.id {
        case ProjectFolderTag.working.id:
            return CyberpunkColors.accent
        case ProjectFolderTag.backup.id:
            return CyberpunkColors.accentTertiary
        case ProjectFolderTag.broken.id:
            return CyberpunkColors.accentSecondary
        case ProjectFolderTag.junk.id:
            return CyberpunkColors.sizeHuge
        case ProjectFolderTag.experiment.id:
            return CyberpunkColors.sizeLarge
        default:
            return CyberpunkColors.textSecondary
        }
    }
}

private struct ProjectTagPicker: View {
    let selectedTag: ProjectFolderTag
    let onSelect: (ProjectFolderTag) -> Void
    let onCustom: () -> Void

    @State private var isPresented = false

    private var selectedColor: Color {
        ProjectTagStyle.color(for: selectedTag)
    }

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(selectedColor)
                    .frame(width: 7, height: 7)
                Text(selectedTag.name)
                    .font(CyberpunkTypography.body(10).weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 110)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundStyle(selectedColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(selectedColor.opacity(0.14))
            .overlay {
                Capsule()
                    .stroke(selectedColor.opacity(0.28), lineWidth: 1)
            }
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(ProjectFolderTag.defaults) { tag in
                    tagButton(tag)
                }

                Divider()
                    .background(CyberpunkColors.borderSubtle)
                    .padding(.vertical, 3)

                Button {
                    isPresented = false
                    onCustom()
                } label: {
                    Label("Custom Tag…", systemImage: "tag")
                        .font(CyberpunkTypography.body(12).weight(.medium))
                        .foregroundStyle(CyberpunkColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .frame(width: 190)
            .background(CyberpunkColors.bgElevated)
            .preferredColorScheme(.dark)
        }
        .fixedSize()
        .accessibilityLabel("Folder tag: \(selectedTag.name)")
    }

    private func tagButton(_ tag: ProjectFolderTag) -> some View {
        let color = ProjectTagStyle.color(for: tag)
        let isSelected = tag == selectedTag

        return Button {
            isPresented = false
            onSelect(tag)
        } label: {
            HStack(spacing: 9) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(tag.name)
                    .font(CyberpunkTypography.body(12).weight(isSelected ? .semibold : .medium))
                    .foregroundStyle(color)
                Spacer(minLength: 8)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(color)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? color.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ProjectManagerView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.detailWidth) private var detailWidth
    @Environment(\.detailHeight) private var detailHeight
    @ObservedObject private var settings = AppSettings.shared
    @State private var showCreateProject = false
    @State private var newProjectName = ""
    @State private var showRenameProject = false
    @State private var renamedProjectName = ""
    @State private var showDeleteProject = false
    @State private var showSuggestions = false
    @State private var folderPendingRemoval: ProjectFolder?
    @State private var folderForCustomTag: ProjectFolder?
    @State private var customTagName = ""

    private var project: ManagedProject? {
        guard let id = appState.selectedProjectID else { return nil }
        return appState.projectStore.project(id: id)
    }

    private var repositoryStatusTaskID: String {
        guard let project else { return "projects" }
        return ([project.id.uuidString] + project.folders.map(\.id.uuidString))
            .joined(separator: ":")
    }

    private var projects: [ManagedProject] {
        appState.projectStore.projects.sorted {
            if $0.totalAllocatedBytes == $1.totalAllocatedBytes {
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
            return $0.totalAllocatedBytes > $1.totalAllocatedBytes
        }
    }

    private var totalTrackedBytes: Int64 {
        projects.reduce(0) { $0 + $1.totalAllocatedBytes }
    }

    private var totalFolderCount: Int {
        projects.reduce(0) { $0 + $1.folders.count }
    }

    private var attentionFolderCount: Int {
        projects.reduce(0) { count, project in
            count + project.folders.filter { $0.availability != .available }.count
        }
    }

    private var largestProjectBytes: Int64 {
        max(projects.map(\.totalAllocatedBytes).max() ?? 0, 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            if let banner = appState.feedbackBanner {
                CyberpunkFeedbackBanner(banner: banner) {
                    appState.dismissFeedback()
                }
                .padding(.horizontal, AppLayout.edge)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Group {
                if let project {
                    projectContent(project)
                } else {
                    managerLanding
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CyberpunkColors.bgPrimary)
        .sheet(isPresented: $showCreateProject) {
            createProjectSheet
        }
        .sheet(isPresented: $showSuggestions) {
            if let project {
                ProjectSuggestionsView(projectID: project.id)
                    .environmentObject(appState)
            }
        }
        .task(id: repositoryStatusTaskID) {
            guard let projectID = appState.selectedProjectID else { return }
            await appState.refreshProjectRepositoryStatuses(
                projectID: projectID,
                reportsCompletion: false
            )
        }
        .alert("Rename Project", isPresented: $showRenameProject) {
            TextField("Project name", text: $renamedProjectName)
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                guard let project else { return }
                appState.renameProject(id: project.id, to: renamedProjectName)
            }
            .disabled(renamedProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .alert("Remove Project?", isPresented: $showDeleteProject) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                guard let project else { return }
                appState.deleteProject(id: project.id)
            }
        } message: {
            Text("This removes the project catalog entry only. No folders or files will be deleted.")
        }
        .alert(
            "Remove Folder?",
            isPresented: Binding(
                get: { folderPendingRemoval != nil },
                set: { if !$0 { folderPendingRemoval = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { folderPendingRemoval = nil }
            Button("Remove", role: .destructive) {
                guard let folder = folderPendingRemoval, let project else { return }
                appState.removeFolder(id: folder.id, from: project.id)
                folderPendingRemoval = nil
            }
        } message: {
            Text("This removes the association only. The folder will remain on disk.")
        }
        .alert(
            "Custom Folder Tag",
            isPresented: Binding(
                get: { folderForCustomTag != nil },
                set: { if !$0 { folderForCustomTag = nil } }
            )
        ) {
            TextField("Tag name", text: $customTagName)
            Button("Cancel", role: .cancel) {
                folderForCustomTag = nil
                customTagName = ""
            }
            Button("Apply") {
                guard let folder = folderForCustomTag, let project else { return }
                appState.setTag(ProjectFolderTag(customTagName), for: folder.id, in: project.id)
                folderForCustomTag = nil
                customTagName = ""
            }
            .disabled(customTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var managerLanding: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                dashboardHeader
                dashboardMetrics

                if projects.isEmpty {
                    dashboardEmptyState
                } else {
                    projectInventory
                }
            }
            .frame(maxWidth: ResponsiveLayout.readableContentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(AppLayout.content)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var dashboardHeader: some View {
        if projects.isEmpty {
            dashboardIdentity
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 20) {
                    dashboardIdentity
                    Spacer(minLength: 12)
                    createProjectButton
                }
                VStack(alignment: .leading, spacing: 14) {
                    dashboardIdentity
                    createProjectButton
                }
            }
        }
    }

    private var dashboardIdentity: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Projects")
                .font(CyberpunkTypography.display(26))
                .foregroundStyle(CyberpunkColors.textPrimary)
            Text("Track related working copies, backups, and experiments in one catalog.")
                .font(CyberpunkTypography.body(13))
                .foregroundStyle(CyberpunkColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Label("Files stay in place and are never copied or deleted", systemImage: "checkmark.shield")
                .font(CyberpunkTypography.body(10))
                .foregroundStyle(CyberpunkColors.textMuted)
        }
    }

    private var createProjectButton: some View {
        Button {
            newProjectName = ""
            showCreateProject = true
        } label: {
            Label("Create Project", systemImage: "plus")
        }
        .buttonStyle(CyberpunkPrimaryButton())
        .accessibilityHint("Opens the new project form")
    }

    private var dashboardMetrics: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 0) {
                dashboardMetric(label: "Tracked Space", value: ByteFormatting.string(for: totalTrackedBytes))
                dashboardMetricDivider
                dashboardMetric(label: "Projects", value: "\(projects.count)")
                dashboardMetricDivider
                dashboardMetric(label: "Folders", value: "\(totalFolderCount)")
                dashboardMetricDivider
                dashboardMetric(
                    label: "Needs Attention",
                    value: "\(attentionFolderCount)",
                    accent: attentionFolderCount > 0 ? CyberpunkColors.accentWarn : CyberpunkColors.accent
                )
            }

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    dashboardMetric(label: "Tracked Space", value: ByteFormatting.string(for: totalTrackedBytes))
                    dashboardMetricDivider
                    dashboardMetric(label: "Projects", value: "\(projects.count)")
                }
                dashboardMetricHorizontalDivider
                HStack(spacing: 0) {
                    dashboardMetric(label: "Folders", value: "\(totalFolderCount)")
                    dashboardMetricDivider
                    dashboardMetric(
                        label: "Needs Attention",
                        value: "\(attentionFolderCount)",
                        accent: attentionFolderCount > 0 ? CyberpunkColors.accentWarn : CyberpunkColors.accent
                    )
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(CyberpunkColors.bgSecondary.opacity(0.65))
        .overlay(
            RoundedRectangle(cornerRadius: CyberpunkColors.controlRadius)
                .stroke(CyberpunkColors.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: CyberpunkColors.controlRadius))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Project portfolio summary")
    }

    private func dashboardMetric(
        label: String,
        value: String,
        accent: Color = CyberpunkColors.textPrimary
    ) -> some View {
        DashboardMetric(label: label, value: value, accent: accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
    }

    private var dashboardMetricDivider: some View {
        Rectangle()
            .fill(CyberpunkColors.borderSubtle)
            .frame(width: 1)
            .padding(.vertical, 8)
    }

    private var dashboardMetricHorizontalDivider: some View {
        Rectangle()
            .fill(CyberpunkColors.borderSubtle)
            .frame(height: 1)
    }

    private var dashboardEmptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(CyberpunkColors.accent)
            Text("Build your project catalog")
                .font(CyberpunkTypography.display(18))
                .foregroundStyle(CyberpunkColors.textPrimary)
            Text("Create a project, then group its working folders, backups, experiments, and archives to see their combined disk usage.")
                .font(CyberpunkTypography.body(12))
                .foregroundStyle(CyberpunkColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520)
            createProjectButton
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppLayout.content)
        .padding(.vertical, 48)
        .background(CyberpunkColors.bgElevated)
        .overlay(
            RoundedRectangle(cornerRadius: CyberpunkColors.cardRadius)
                .stroke(CyberpunkColors.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: CyberpunkColors.cardRadius))
    }

    private var projectInventory: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Project Inventory")
                        .font(CyberpunkTypography.display(16))
                        .foregroundStyle(CyberpunkColors.textPrimary)
                    Text("Largest tracked projects appear first")
                        .font(CyberpunkTypography.body(10))
                        .foregroundStyle(CyberpunkColors.textMuted)
                }
                Spacer()
                Text("\(projects.count) total")
                    .font(CyberpunkTypography.mono(10))
                    .foregroundStyle(CyberpunkColors.textMuted)
            }
            .padding(AppLayout.edge)

            Divider().background(CyberpunkColors.borderSubtle)

            ForEach(Array(projects.enumerated()), id: \.element.id) { index, project in
                dashboardProjectRow(project)
                if index < projects.count - 1 {
                    Divider()
                        .background(CyberpunkColors.borderSubtle)
                        .padding(.horizontal, AppLayout.edge)
                }
            }
        }
        .background(CyberpunkColors.bgElevated)
        .overlay(
            RoundedRectangle(cornerRadius: CyberpunkColors.cardRadius)
                .stroke(CyberpunkColors.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: CyberpunkColors.cardRadius))
    }

    private func dashboardProjectRow(_ project: ManagedProject) -> some View {
        Button {
            appState.selectProject(id: project.id)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 16) {
                        dashboardProjectIdentity(project)
                        Spacer(minLength: 8)
                        dashboardProjectMetrics(project)
                        projectHealth(project)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(CyberpunkColors.textMuted)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 10) {
                            dashboardProjectIdentity(project)
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(CyberpunkColors.textMuted)
                        }
                        HStack(spacing: 14) {
                            dashboardProjectMetrics(project)
                            Spacer(minLength: 8)
                            projectHealth(project)
                        }
                    }
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(CyberpunkColors.bgSecondary)
                        Capsule()
                            .fill(CyberpunkColors.accentGradient)
                            .frame(
                                width: geometry.size.width * CGFloat(
                                    Double(project.totalAllocatedBytes) / Double(largestProjectBytes)
                                )
                            )
                    }
                }
                .frame(height: 5)
                .accessibilityHidden(true)
            }
            .padding(.horizontal, AppLayout.edge)
            .padding(.vertical, 15)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(project.name)
        .accessibilityValue(projectAccessibilityValue(project))
        .accessibilityHint("Opens project details")
    }

    private func dashboardProjectIdentity(_ project: ManagedProject) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(project.name)
                .font(CyberpunkTypography.body(14).weight(.semibold))
                .foregroundStyle(CyberpunkColors.textPrimary)
                .lineLimit(1)
            Text(project.folders.isEmpty ? "No folders added" : "\(project.folders.count) folder\(project.folders.count == 1 ? "" : "s")")
                .font(CyberpunkTypography.body(10))
                .foregroundStyle(CyberpunkColors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .layoutPriority(1)
    }

    private func dashboardProjectMetrics(_ project: ManagedProject) -> some View {
        HStack(spacing: 18) {
            compactProjectMetric(
                label: "Space",
                value: ByteFormatting.string(for: project.totalAllocatedBytes)
            )
            compactProjectMetric(label: "Last Scan", value: lastScanText(project))
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func compactProjectMetric(label: String, value: String) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(label.uppercased())
                .font(CyberpunkTypography.sectionLabel(8))
                .foregroundStyle(CyberpunkColors.textMuted)
            Text(value)
                .font(CyberpunkTypography.mono(10))
                .foregroundStyle(CyberpunkColors.textSecondary)
                .lineLimit(1)
        }
    }

    private func projectHealth(_ project: ManagedProject) -> some View {
        let status = projectHealthStatus(project)
        return Label(status.label, systemImage: status.icon)
            .font(CyberpunkTypography.body(10).weight(.semibold))
            .foregroundStyle(status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(status.color.opacity(0.1))
            .clipShape(Capsule())
            .fixedSize()
    }

    private func projectHealthStatus(_ project: ManagedProject) -> (label: String, icon: String, color: Color) {
        let unavailableCount = project.folders.filter { $0.availability != .available }.count
        if unavailableCount > 0 {
            return ("\(unavailableCount) attention", "exclamationmark.triangle.fill", CyberpunkColors.accentWarn)
        }
        if project.folders.isEmpty {
            return ("No folders", "folder.badge.plus", CyberpunkColors.textMuted)
        }
        if project.lastScannedAt == nil {
            return ("Not scanned", "clock", CyberpunkColors.accentSecondary)
        }
        return ("Available", "checkmark.circle.fill", CyberpunkColors.accent)
    }

    private func projectAccessibilityValue(_ project: ManagedProject) -> String {
        let status = projectHealthStatus(project).label
        return "\(ByteFormatting.string(for: project.totalAllocatedBytes)) tracked, \(project.folders.count) folders, last scan \(lastScanText(project)), \(status)"
    }

    private func projectContent(_ project: ManagedProject) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if detailHeight < ResponsiveLayout.compactDetailHeight {
                ScrollView {
                    projectHeader(project)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxHeight: ResponsiveLayout.projectHeaderMaxHeight(for: detailHeight))
            } else {
                projectHeader(project)
            }

            if appState.isScanningProject {
                ScanProgressView(
                    progress: appState.projectScanProgress,
                    message: appState.projectScanMessage ?? "Measuring folders…",
                    label: "Project folder scan progress"
                )
                .padding(AppLayout.edge)
                .accessibilityValue("Busy")
            }

            if project.folders.isEmpty {
                projectEmptyState(project)
            } else {
                folderList(project)
            }
        }
        .animation(
            CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
            value: appState.feedbackBanner
        )
    }

    private func projectHeader(_ project: ManagedProject) -> some View {
        VStack(alignment: .leading, spacing: detailHeight < ResponsiveLayout.compactDetailHeight ? 10 : 14) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    projectIdentity(project)
                    Spacer(minLength: 8)
                    projectActions(project)
                }
                VStack(alignment: .leading, spacing: 12) {
                    projectIdentity(project)
                    projectActions(project)
                }
            }

            ViewThatFits(in: .horizontal) {
                projectMetricsRow(project)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 20) {
                        metric(label: "Tracked space", value: ByteFormatting.string(for: project.totalAllocatedBytes))
                        metric(label: "Folders", value: "\(project.folders.count)")
                    }
                    metric(label: "Last scan", value: lastScanText(project))
                }

                VStack(alignment: .leading, spacing: 8) {
                    metric(label: "Tracked space", value: ByteFormatting.string(for: project.totalAllocatedBytes))
                    metric(label: "Folders", value: "\(project.folders.count)")
                    metric(label: "Last scan", value: lastScanText(project))
                }
            }
        }
        .frame(maxWidth: ResponsiveLayout.readableContentMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity)
        .padding(detailHeight < ResponsiveLayout.compactDetailHeight ? AppLayout.compactEdge : AppLayout.edge)
        .background(CyberpunkColors.bgSecondary)
    }

    private func projectMetricsRow(_ project: ManagedProject) -> some View {
        HStack(spacing: 20) {
            metric(label: "Tracked space", value: ByteFormatting.string(for: project.totalAllocatedBytes))
            metric(label: "Folders", value: "\(project.folders.count)")
            metric(label: "Last scan", value: lastScanText(project))
        }
    }

    private func projectIdentity(_ project: ManagedProject) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(project.name)
                .font(CyberpunkTypography.display(20))
                .foregroundStyle(CyberpunkColors.textPrimary)
                .lineLimit(2)
            Text("Catalog-only manager · files are never copied or deleted")
                .font(CyberpunkTypography.body(11))
                .foregroundStyle(CyberpunkColors.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func projectActions(_ project: ManagedProject) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                primaryProjectActions(project)
                projectMenu(project)
            }
            VStack(alignment: .leading, spacing: 8) {
                primaryProjectActions(project)
                projectMenu(project)
            }
        }
    }

    private func primaryProjectActions(_ project: ManagedProject) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                scanAndSuggestButton
                addFolderButton(project)
            }
            VStack(alignment: .leading, spacing: 8) {
                scanAndSuggestButton
                addFolderButton(project)
            }
        }
    }

    private var scanAndSuggestButton: some View {
        Button {
            appState.clearProjectSuggestions()
            showSuggestions = true
        } label: {
            Label("Scan & Suggest", systemImage: "sparkle.magnifyingglass")
        }
        .buttonStyle(CyberpunkPrimaryButton())
        .disabled(appState.isSuggestingFolders)
    }

    private func addFolderButton(_ project: ManagedProject) -> some View {
        Button {
            chooseFolders(for: project)
        } label: {
            Label("Add Folder", systemImage: "folder.badge.plus")
        }
        .buttonStyle(CyberpunkSecondaryButton())
    }

    private func projectMenu(_ project: ManagedProject) -> some View {
        Menu {
            Button("Refresh Folder Sizes") {
                Task { await appState.refreshProjectSizes(projectID: project.id) }
            }
            .disabled(project.folders.isEmpty || appState.isScanningProject)
            Button {
                Task {
                    await appState.refreshProjectRepositoryStatuses(projectID: project.id)
                }
            } label: {
                Label(
                    appState.isRefreshingProjectRepositoryStatuses
                        ? "Refreshing Git & GitHub Status…"
                        : "Refresh Git & GitHub Status",
                    systemImage: appState.isRefreshingProjectRepositoryStatuses
                        ? "arrow.trianglehead.2.clockwise.rotate.90"
                        : "arrow.clockwise"
                )
            }
            .disabled(
                project.folders.isEmpty
                    || appState.isRefreshingProjectRepositoryStatuses
            )
            Button("Rename Project") {
                renamedProjectName = project.name
                showRenameProject = true
            }
            Divider()
            Button("Remove Project", role: .destructive) {
                showDeleteProject = true
            }
        } label: {
            Image(systemName: "ellipsis")
                .frame(width: 28, height: 20)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private func metric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(CyberpunkTypography.sectionLabel(9))
                .foregroundStyle(CyberpunkColors.textMuted)
            Text(value)
                .font(CyberpunkTypography.mono(12))
                .foregroundStyle(CyberpunkColors.textPrimary)
                .lineLimit(1)
        }
    }

    private func projectEmptyState(_ project: ManagedProject) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 38))
                .foregroundStyle(CyberpunkColors.textMuted)
            Text("Add the first folder for \(project.name)")
                .font(CyberpunkTypography.display(16))
                .foregroundStyle(CyberpunkColors.textSecondary)
            Text("Choose folders directly or scan selected locations for suggestions.")
                .font(CyberpunkTypography.body(12))
                .foregroundStyle(CyberpunkColors.textMuted)
                .multilineTextAlignment(.center)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    addFolderButton(project)
                    scanAndSuggestButton
                }
                VStack(spacing: 8) {
                    addFolderButton(project)
                    scanAndSuggestButton
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func folderList(_ project: ManagedProject) -> some View {
        let folders = settings.projectFolderSortField.sorted(
            project.folders,
            ascending: settings.projectFolderSortAscending
        )

        return VStack(spacing: 0) {
            folderSortBar(folderCount: folders.count)

            Divider()
                .background(CyberpunkColors.borderSubtle)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(folders.enumerated()), id: \.element.id) { index, folder in
                        folderRow(folder, project: project)
                        if index < folders.count - 1 {
                            Divider()
                                .background(CyberpunkColors.borderSubtle)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func folderSortBar(folderCount: Int) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                folderSortIdentity(folderCount: folderCount)
                Spacer(minLength: 12)
                folderSortControls
            }

            VStack(alignment: .leading, spacing: 10) {
                folderSortIdentity(folderCount: folderCount)
                folderSortControls
            }
        }
        .padding(.horizontal, detailWidth < ResponsiveLayout.compactDetailWidth ? AppLayout.compactEdge : AppLayout.edge)
        .padding(.vertical, 10)
        .background(CyberpunkColors.bgSecondary.opacity(0.7))
    }

    private func folderSortIdentity(folderCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Project Folders")
                .font(CyberpunkTypography.body(12).weight(.semibold))
                .foregroundStyle(CyberpunkColors.textPrimary)
            Text("\(folderCount) tracked · sorted by \(settings.projectFolderSortField.title.lowercased())")
                .font(CyberpunkTypography.body(9))
                .foregroundStyle(CyberpunkColors.textMuted)
        }
    }

    private var folderSortControls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                folderSortFieldMenu
                folderSortDirectionButton
            }
            VStack(alignment: .leading, spacing: 8) {
                folderSortFieldMenu
                folderSortDirectionButton
            }
        }
    }

    private var folderSortFieldMenu: some View {
        Menu {
            Picker("Sort folders by", selection: $settings.projectFolderSortField) {
                ForEach(ProjectFolderSortField.allCases) { field in
                    Label(field.title, systemImage: folderSortIcon(field))
                        .tag(field)
                }
            }
        } label: {
            Label(
                "Sort: \(settings.projectFolderSortField.title)",
                systemImage: folderSortIcon(settings.projectFolderSortField)
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .accessibilityLabel("Sort folders by")
        .accessibilityValue(settings.projectFolderSortField.title)
    }

    private var folderSortDirectionButton: some View {
        Button {
            settings.projectFolderSortAscending.toggle()
        } label: {
            Label(
                settings.projectFolderSortAscending ? "Ascending" : "Descending",
                systemImage: settings.projectFolderSortAscending ? "arrow.up" : "arrow.down"
            )
        }
        .buttonStyle(CyberpunkSecondaryButton())
        .fixedSize()
        .accessibilityLabel("Folder sort direction")
        .accessibilityValue(settings.projectFolderSortAscending ? "Ascending" : "Descending")
    }

    private func folderSortIcon(_ field: ProjectFolderSortField) -> String {
        switch field {
        case .size:
            return "internaldrive"
        case .tag:
            return "tag"
        case .name:
            return "textformat"
        case .location:
            return "folder"
        }
    }

    private func folderRow(_ folder: ProjectFolder, project: ManagedProject) -> some View {
        let largest = max(project.folders.compactMap(\.allocatedBytes).max() ?? 0, 1)
        let fraction = min(1, Double(folder.allocatedBytes ?? 0) / Double(largest))

        return VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 12) {
                    folderIdentity(folder)
                    Spacer(minLength: 8)
                    repositoryStatus(folder, fillsWidth: false)
                    folderSize(folder)
                    tagMenu(folder, project: project)
                    folderMenu(folder, project: project)
                }
                VStack(alignment: .leading, spacing: 8) {
                    folderIdentity(folder)
                    repositoryStatus(folder, fillsWidth: true)
                    folderRowActions(folder, project: project)
                }
                VStack(alignment: .leading, spacing: 8) {
                    folderIdentity(folder)
                    repositoryStatus(folder, fillsWidth: true)
                    folderSize(folder)
                    HStack(spacing: 8) {
                        tagMenu(folder, project: project)
                        folderMenu(folder, project: project)
                    }
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(CyberpunkColors.bgElevated)
                    Capsule()
                        .fill(CyberpunkColors.accentGradient)
                        .frame(width: geometry.size.width * fraction)
                }
            }
            .frame(height: 6)
            .accessibilityLabel("\(folder.name) relative disk usage")
            .accessibilityValue("\(Int(fraction * 100)) percent of largest tracked folder")
        }
        .padding(.horizontal, detailWidth < ResponsiveLayout.compactDetailWidth ? AppLayout.compactEdge : AppLayout.edge)
        .padding(.vertical, detailHeight < ResponsiveLayout.compactDetailHeight ? 10 : 14)
    }

    private func folderRowActions(_ folder: ProjectFolder, project: ManagedProject) -> some View {
        HStack(spacing: 8) {
            folderSize(folder)
            Spacer(minLength: 8)
            tagMenu(folder, project: project)
            folderMenu(folder, project: project)
        }
    }

    private func folderIdentity(_ folder: ProjectFolder) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Button {
                FileRevealService.reveal(path: folder.path)
            } label: {
                Text(folder.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .buttonStyle(.link)
            .font(CyberpunkTypography.body(13).weight(.semibold))
            .foregroundStyle(CyberpunkColors.textPrimary)
            Text(folder.path)
                .font(CyberpunkTypography.mono(10))
                .foregroundStyle(CyberpunkColors.textMuted)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .layoutPriority(1)
    }

    private func repositoryStatus(_ folder: ProjectFolder, fillsWidth: Bool) -> some View {
        let status = appState.projectRepositoryStatuses[folder.id]

        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Text("GIT & GITHUB")
                    .font(CyberpunkTypography.sectionLabel(8))
                    .foregroundStyle(CyberpunkColors.textMuted)
                if appState.isRefreshingProjectRepositoryStatuses {
                    ProgressView()
                        .controlSize(.mini)
                }
            }

            repositoryStatusContent(status)
        }
        .frame(
            minWidth: fillsWidth ? 0 : 140,
            idealWidth: fillsWidth ? nil : 170,
            maxWidth: fillsWidth ? .infinity : 190,
            alignment: .leading
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Git and GitHub status")
        .accessibilityValue(repositoryAccessibilityValue(status))
        .help(repositoryHelp(status))
    }

    @ViewBuilder
    private func repositoryStatusContent(_ status: GitRepositoryStatus?) -> some View {
        if let status {
            switch status.state {
            case .repository:
                HStack(spacing: 5) {
                    Image(systemName: status.hasChanges ? "circle.lefthalf.filled" : "checkmark.circle.fill")
                    Text("\(status.branch ?? "Unknown branch") · \(status.hasChanges ? "Changes" : "Clean")")
                        .lineLimit(1)
                }
                .font(CyberpunkTypography.mono(10))
                .foregroundStyle(
                    status.hasChanges ? CyberpunkColors.accentWarn : CyberpunkColors.accent
                )

                Text(githubStatusText(status))
                    .font(CyberpunkTypography.body(9).weight(.medium))
                    .foregroundStyle(
                        status.githubRemoteURL == nil
                            ? CyberpunkColors.textMuted
                            : CyberpunkColors.accentTertiary
                    )
                    .lineLimit(1)
            case .notRepository:
                Label("Not a Git repository", systemImage: "minus.circle")
                    .font(CyberpunkTypography.body(10))
                    .foregroundStyle(CyberpunkColors.textMuted)
            case .unavailable:
                Label("Status unavailable", systemImage: "exclamationmark.triangle")
                    .font(CyberpunkTypography.body(10))
                    .foregroundStyle(CyberpunkColors.accentWarn)
            }
        } else if appState.isRefreshingProjectRepositoryStatuses {
            Text("Checking…")
                .font(CyberpunkTypography.body(10))
                .foregroundStyle(CyberpunkColors.textSecondary)
        } else {
            Text("Not checked")
                .font(CyberpunkTypography.body(10))
                .foregroundStyle(CyberpunkColors.textMuted)
        }
    }

    private func githubStatusText(_ status: GitRepositoryStatus) -> String {
        guard let upstream = status.upstream else {
            return status.githubRemoteURL == nil ? "No GitHub remote" : "GitHub · No upstream"
        }
        let remoteName = status.githubRemoteURL == nil ? "No GitHub" : "GitHub"
        if upstream.ahead == 0 && upstream.behind == 0 {
            return "\(remoteName) · Up to date"
        }
        return "\(remoteName) · ↑\(upstream.ahead) ↓\(upstream.behind)"
    }

    private func repositoryAccessibilityValue(_ status: GitRepositoryStatus?) -> String {
        guard let status else {
            return appState.isRefreshingProjectRepositoryStatuses ? "Checking" : "Not checked"
        }
        switch status.state {
        case .repository:
            let workingTree = status.hasChanges ? "has local changes" : "clean"
            return "\(status.branch ?? "Unknown branch"), \(workingTree), \(githubStatusText(status)). Upstream comparison uses locally fetched refs."
        case .notRepository:
            return "Not a Git repository"
        case .unavailable:
            return "Status unavailable"
        }
    }

    private func repositoryHelp(_ status: GitRepositoryStatus?) -> String {
        guard status?.state == .repository else {
            return "Git and GitHub status for this folder."
        }
        return "Ahead and behind counts use locally fetched refs. No network request is made."
    }

    private func folderSize(_ folder: ProjectFolder) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(folder.allocatedBytes.map(ByteFormatting.string(for:)) ?? "Not scanned")
                .font(CyberpunkTypography.mono(12))
                .foregroundStyle(folder.availability == .available ? CyberpunkColors.accent : CyberpunkColors.accentWarn)
                .lineLimit(1)
            if folder.availability != .available {
                Text(folder.availability == .missing ? "Missing" : "Inaccessible")
                    .font(CyberpunkTypography.body(9))
                    .foregroundStyle(CyberpunkColors.accentWarn)
            }
        }
    }

    private func tagMenu(_ folder: ProjectFolder, project: ManagedProject) -> some View {
        ProjectTagPicker(
            selectedTag: folder.tag,
            onSelect: { tag in
                appState.setTag(tag, for: folder.id, in: project.id)
            },
            onCustom: {
                customTagName = folder.tag.name
                folderForCustomTag = folder
            }
        )
    }

    private func folderMenu(_ folder: ProjectFolder, project: ManagedProject) -> some View {
        Menu {
            Button("Show in Finder") {
                FileRevealService.reveal(path: folder.path)
            }
            Button("Remove from Project", role: .destructive) {
                folderPendingRemoval = folder
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(CyberpunkColors.textSecondary)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private var createProjectSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create Project")
                .font(CyberpunkTypography.display(18))
            Text("A project groups related working copies, backups, experiments, and other folders.")
                .font(CyberpunkTypography.body(12))
                .foregroundStyle(CyberpunkColors.textSecondary)
            TextField("Project name", text: $newProjectName)
                .textFieldStyle(.roundedBorder)
                .onSubmit(createProject)
            HStack {
                Spacer()
                Button("Cancel") { showCreateProject = false }
                    .buttonStyle(CyberpunkSecondaryButton())
                Button("Create", action: createProject)
                    .buttonStyle(CyberpunkPrimaryButton())
                    .disabled(newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 430)
        .background(CyberpunkColors.bgPrimary)
        .preferredColorScheme(.dark)
    }

    private func createProject() {
        let name = newProjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        appState.createProject(named: name)
        showCreateProject = false
        newProjectName = ""
    }

    private func chooseFolders(for project: ManagedProject) {
        let panel = NSOpenPanel()
        panel.title = "Add Folders to \(project.name)"
        panel.prompt = "Add Folders"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.canCreateDirectories = false
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            appState.addFolder(path: url.path, tag: .working, to: project.id)
        }
        Task {
            await appState.refreshProjectSizes(projectID: project.id)
            await appState.refreshProjectRepositoryStatuses(
                projectID: project.id,
                reportsCompletion: false
            )
        }
    }

    private func lastScanText(_ project: ManagedProject) -> String {
        guard let date = project.lastScannedAt else { return "Never" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
