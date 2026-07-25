import SwiftUI

private struct SidebarSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(CyberpunkTypography.body(11).weight(.semibold))
            .foregroundStyle(CyberpunkColors.textMuted)
            .textCase(.uppercase)
            .padding(.top, AppLayout.sidebarSectionSpacing)
    }
}

struct CategoryRowView: View {
    let category: CleanupCategory
    let result: CategoryScanResult?
    let status: ScanStatus
    let isSelected: Bool
    let hasFDA: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var scanProgress: Double? {
        if case .scanning(let progress, _) = status { return progress }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: category.systemImage)
                    .frame(width: 20, height: 20, alignment: .center)
                    .foregroundStyle(isSelected ? CyberpunkColors.accent : CyberpunkColors.textSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(CyberpunkTypography.body(13).weight(.medium))
                        .foregroundStyle(CyberpunkColors.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(subtitle)
                        .font(CyberpunkTypography.body(10))
                        .foregroundStyle(subtitleColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(1)
                        .contentTransition(.numericText())
                        .animation(
                            CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
                            value: subtitle
                        )
                }

                Spacer(minLength: 4)

                statusBadge
                    .frame(width: 12, alignment: .center)
                    .animation(
                        CyberpunkAnimation.apply(CyberpunkAnimation.quick, reduceMotion: reduceMotion),
                        value: statusAnimationKey
                    )
            }
            .padding(.horizontal, AppLayout.sidebarRowHorizontal)
            .padding(.vertical, AppLayout.sidebarRowVertical)

            if let progress = scanProgress {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(CyberpunkColors.bgSecondary)
                            .frame(height: 2)
                        Rectangle()
                            .fill(CyberpunkColors.accent)
                            .frame(width: geometry.size.width * CGFloat(progress), height: 2)
                    }
                }
                .frame(height: 2)
                .padding(.horizontal, 10)
                .padding(.bottom, 4)
                .transition(.opacity)
            }
        }
        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .listRowBackground(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? CyberpunkColors.accentDim : Color.clear)
        )
        .listRowSeparator(.hidden)
        .animation(
            CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
            value: isSelected
        )
        .animation(
            CyberpunkAnimation.apply(CyberpunkAnimation.quick, reduceMotion: reduceMotion),
            value: scanProgress
        )
    }

    private var statusAnimationKey: String {
        switch status {
        case .idle:
            if let result, !result.items.isEmpty {
                return "idle-\(result.items.count)"
            }
            return "idle"
        case .scanning:
            return "scanning"
        case .completed:
            return "completed"
        case .failed:
            return "failed"
        }
    }

    private var subtitleColor: Color {
        if category.requiresFullDiskAccess && !hasFDA {
            return CyberpunkColors.textMuted
        }
        if let result, !result.items.isEmpty {
            return ByteFormatting.reclaimableColor(for: result.totalBytes)
        }
        return CyberpunkColors.textMuted
    }

    private var reclaimableBytes: Int64? {
        guard let result, !result.items.isEmpty else { return nil }
        return result.totalBytes
    }

    private var subtitle: String {
        if category.requiresFullDiskAccess && !hasFDA {
            return "Needs Full Disk Access"
        }
        if let result, !result.items.isEmpty {
            return ByteFormatting.string(for: result.totalBytes)
        }
        if category.isGuidedOnly {
            return "Guided"
        }
        return "Ready to scan"
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch status {
        case .idle:
            if let bytes = reclaimableBytes {
                Circle()
                    .fill(ByteFormatting.reclaimableColor(for: bytes))
                    .frame(width: 6, height: 6)
                    .transition(.scale.combined(with: .opacity))
            }
        case .scanning:
            CyberpunkPulseDot(color: scanningDotColor)
                .transition(.scale.combined(with: .opacity))
        case .completed:
            if let bytes = reclaimableBytes {
                Circle()
                    .fill(ByteFormatting.reclaimableColor(for: bytes))
                    .frame(width: 6, height: 6)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Circle()
                    .fill(CyberpunkColors.accent)
                    .frame(width: 6, height: 6)
                    .transition(.scale.combined(with: .opacity))
            }
        case .failed:
            Circle()
                .fill(CyberpunkColors.accentSecondary)
                .frame(width: 6, height: 6)
                .transition(.scale.combined(with: .opacity))
        }
    }

    private var scanningDotColor: Color {
        if let bytes = reclaimableBytes {
            return ByteFormatting.reclaimableColor(for: bytes)
        }
        return CyberpunkColors.accent
    }
}

struct SettingsRowView: View {
    let isSelected: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "gearshape")
                .frame(width: 20, height: 20, alignment: .center)
                .foregroundStyle(isSelected ? CyberpunkColors.accent : CyberpunkColors.textSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(CyberpunkTypography.body(13).weight(.medium))
                    .foregroundStyle(CyberpunkColors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("Scan thresholds & privacy")
                    .font(CyberpunkTypography.body(10))
                    .foregroundStyle(CyberpunkColors.textMuted)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 4)

            Color.clear
                .frame(width: 12, height: 6)
        }
        .padding(.horizontal, AppLayout.sidebarRowHorizontal)
        .padding(.vertical, AppLayout.sidebarRowVertical)
        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .listRowBackground(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? CyberpunkColors.accentDim : Color.clear)
        )
        .listRowSeparator(.hidden)
        .animation(
            CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
            value: isSelected
        )
    }
}

struct ProjectSidebarRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .frame(width: 20, height: 20)
                .foregroundStyle(isSelected ? CyberpunkColors.accent : CyberpunkColors.textSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(CyberpunkTypography.body(13).weight(.medium))
                    .foregroundStyle(CyberpunkColors.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(CyberpunkTypography.body(10))
                    .foregroundStyle(CyberpunkColors.textMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)
        }
        .padding(.horizontal, AppLayout.sidebarRowHorizontal)
        .padding(.vertical, AppLayout.sidebarRowVertical)
        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .listRowBackground(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? CyberpunkColors.accentDim : Color.clear)
        )
        .listRowSeparator(.hidden)
    }
}

struct CategoryListView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List(selection: Binding(
            get: { appState.sidebarSelection },
            set: { newValue in
                guard let newValue else { return }
                switch newValue {
                case .category(let id):
                    if let cat = CleanupCategory.byID(id) {
                        appState.selectCategory(cat)
                    }
                case .appManager:
                    appState.selectAppManager()
                case .projects:
                    appState.selectProjects()
                case .project(let id):
                    appState.selectProject(id: id)
                case .settings:
                    appState.selectSettings()
                }
            }
        )) {
            ForEach(CategoryGroup.allCases) { group in
                let categories = CleanupCategory.all.filter { $0.group == group }
                if !categories.isEmpty {
                    Section {
                        ForEach(categories) { category in
                            CategoryRowView(
                                category: category,
                                result: appState.scanEngine.results[category.id],
                                status: appState.scanEngine.statuses[category.id] ?? .idle,
                                isSelected: appState.selectedCategoryID == category.id,
                                hasFDA: appState.hasFullDiskAccess
                            )
                            .tag(SidebarSelection.category(category.id))
                        }
                    } header: {
                        SidebarSectionHeader(title: group.rawValue)
                    }
                }
            }

            Section {
                ProjectSidebarRow(
                    title: "Project Manager",
                    subtitle: "\(appState.projectStore.projects.count) projects",
                    systemImage: "folder.badge.gearshape",
                    isSelected: appState.sidebarSelection == .projects
                )
                .tag(SidebarSelection.projects)

                ForEach(appState.projectStore.projects) { project in
                    ProjectSidebarRow(
                        title: project.name,
                        subtitle: "\(project.folders.count) folders · \(ByteFormatting.string(for: project.totalAllocatedBytes))",
                        systemImage: "folder",
                        isSelected: appState.selectedProjectID == project.id
                    )
                    .tag(SidebarSelection.project(project.id))
                }
            } header: {
                SidebarSectionHeader(title: "Projects")
            }

            Section {
                ProjectSidebarRow(
                    title: "App Manager",
                    subtitle: appState.hasLoadedApplicationInventory
                        ? "\(appState.installedApplications.count) installed"
                        : "Installed applications",
                    systemImage: "square.grid.2x2",
                    isSelected: appState.sidebarSelection == .appManager
                )
                .tag(SidebarSelection.appManager)

                SettingsRowView(isSelected: appState.sidebarSelection == .settings)
                    .tag(SidebarSelection.settings)
            } header: {
                SidebarSectionHeader(title: "App")
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.automatic)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CyberpunkColors.bgSecondary)
    }
}
