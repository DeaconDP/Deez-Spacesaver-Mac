import SwiftUI

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
            HStack(spacing: 10) {
                Image(systemName: category.systemImage)
                    .frame(width: 20)
                    .foregroundStyle(isSelected ? CyberpunkColors.accent : CyberpunkColors.textSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(CyberpunkTypography.body(13).weight(.medium))
                        .foregroundStyle(CyberpunkColors.textPrimary)
                    Text(subtitle)
                        .font(CyberpunkTypography.body(10))
                        .foregroundStyle(CyberpunkColors.textMuted)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                        .animation(
                            CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
                            value: subtitle
                        )
                }

                Spacer()

                statusBadge
                    .animation(
                        CyberpunkAnimation.apply(CyberpunkAnimation.quick, reduceMotion: reduceMotion),
                        value: statusAnimationKey
                    )
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

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
        .background(isSelected ? CyberpunkColors.accentDim : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
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
        return category.description
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch status {
        case .idle:
            if let result, !result.items.isEmpty {
                Text("\(result.items.count)")
                    .font(CyberpunkTypography.mono(10))
                    .foregroundStyle(CyberpunkColors.accent)
                    .transition(.scale.combined(with: .opacity))
            }
        case .scanning:
            ProgressView()
                .scaleEffect(0.6)
                .transition(.scale.combined(with: .opacity))
        case .completed:
            Circle()
                .fill(CyberpunkColors.accent)
                .frame(width: 6, height: 6)
                .transition(.scale.combined(with: .opacity))
        case .failed:
            Circle()
                .fill(CyberpunkColors.accentSecondary)
                .frame(width: 6, height: 6)
                .transition(.scale.combined(with: .opacity))
        }
    }
}

struct SettingsRowView: View {
    let isSelected: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "gearshape")
                .frame(width: 20)
                .foregroundStyle(isSelected ? CyberpunkColors.accent : CyberpunkColors.textSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(CyberpunkTypography.body(13).weight(.medium))
                    .foregroundStyle(CyberpunkColors.textPrimary)
                Text("Scan thresholds & privacy")
                    .font(CyberpunkTypography.body(10))
                    .foregroundStyle(CyberpunkColors.textMuted)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isSelected ? CyberpunkColors.accentDim : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .animation(
            CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
            value: isSelected
        )
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
                case .settings:
                    appState.selectSettings()
                }
            }
        )) {
            ForEach(CategoryGroup.allCases) { group in
                let categories = CleanupCategory.all.filter { $0.group == group }
                if !categories.isEmpty {
                    Section(group.rawValue) {
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
                    }
                }
            }

            Section("App") {
                SettingsRowView(isSelected: appState.sidebarSelection == .settings)
                    .tag(SidebarSelection.settings)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(CyberpunkColors.bgSecondary)
    }
}
