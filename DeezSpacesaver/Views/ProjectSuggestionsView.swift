import AppKit
import SwiftUI

struct ProjectSuggestionsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let projectID: UUID

    @State private var selectedPaths: Set<String> = []
    @State private var selectedTag = ProjectFolderTag.working

    private var project: ManagedProject? {
        appState.projectStore.project(id: projectID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().background(CyberpunkColors.borderSubtle)

            if let banner = appState.feedbackBanner {
                CyberpunkFeedbackBanner(banner: banner) {
                    appState.dismissFeedback()
                }
                .padding(.horizontal, AppLayout.edge)
                .padding(.top, 8)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    searchLocations

                    if appState.isSuggestingFolders {
                        ScanProgressView(
                            progress: nil,
                            message: appState.suggestionProgressMessage ?? "Searching folders…",
                            label: "Project suggestion scan progress"
                        )
                        .accessibilityValue("Busy")
                    }

                    suggestions
                }
                .padding(AppLayout.edge)
            }

            Divider().background(CyberpunkColors.borderSubtle)
            footer
        }
        .frame(minWidth: 620, idealWidth: 760, minHeight: 520, idealHeight: 640)
        .background(CyberpunkColors.bgPrimary)
        .preferredColorScheme(.dark)
        .onChange(of: appState.projectSuggestions) { _, suggestions in
            selectedPaths = selectedPaths.intersection(Set(suggestions.map(\.path)))
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Scan & Suggest")
                    .font(CyberpunkTypography.display(20))
                    .foregroundStyle(CyberpunkColors.textPrimary)
                Text("Find folders that may belong to \(project?.name ?? "this project"). Nothing is added automatically.")
                    .font(CyberpunkTypography.body(12))
                    .foregroundStyle(CyberpunkColors.textSecondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(AppLayout.edge)
        .background(CyberpunkColors.bgSecondary)
    }

    private var searchLocations: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Search locations")
                        .font(CyberpunkTypography.display(14))
                        .foregroundStyle(CyberpunkColors.textPrimary)
                    Text("Only folders you choose here will be searched.")
                        .font(CyberpunkTypography.body(11))
                        .foregroundStyle(CyberpunkColors.textMuted)
                }
                Spacer()
                Button("Choose Locations…") {
                    chooseSearchLocations()
                }
                .buttonStyle(CyberpunkSecondaryButton())
                .disabled(appState.isSuggestingFolders)
            }

            if appState.projectStore.searchRoots.isEmpty {
                Text("No search locations selected.")
                    .font(CyberpunkTypography.body(12))
                    .foregroundStyle(CyberpunkColors.accentWarn)
                    .padding(.vertical, 8)
            } else {
                ForEach(appState.projectStore.searchRoots, id: \.self) { path in
                    HStack(spacing: 8) {
                        Image(systemName: "folder")
                            .foregroundStyle(CyberpunkColors.accent)
                        Text(path)
                            .font(CyberpunkTypography.mono(10))
                            .foregroundStyle(CyberpunkColors.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button {
                            removeSearchRoot(path)
                        } label: {
                            Image(systemName: "xmark.circle")
                        }
                        .buttonStyle(.plain)
                        .disabled(appState.isSuggestingFolders)
                        .accessibilityLabel("Remove \(path)")
                    }
                    .padding(.vertical, 4)
                }
            }

            Button {
                Task { await appState.findProjectSuggestions(projectID: projectID) }
            } label: {
                CyberpunkLoadingLabel(
                    isLoading: appState.isSuggestingFolders,
                    title: appState.isSuggestingFolders ? "Scanning Locations…" : "Scan Selected Locations"
                )
            }
            .buttonStyle(CyberpunkPrimaryButton())
            .disabled(appState.isSuggestingFolders || appState.projectStore.searchRoots.isEmpty)
            .accessibilityValue(appState.isSuggestingFolders ? "Busy" : "Ready")
        }
    }

    @ViewBuilder
    private var suggestions: some View {
        if !appState.isSuggestingFolders && appState.projectSuggestions.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 28))
                    .foregroundStyle(CyberpunkColors.textMuted)
                Text("Choose locations and scan for likely matches.")
                    .font(CyberpunkTypography.body(12))
                    .foregroundStyle(CyberpunkColors.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
        } else if !appState.projectSuggestions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Suggestions")
                    .font(CyberpunkTypography.display(14))
                    .foregroundStyle(CyberpunkColors.textPrimary)

                ForEach(appState.projectSuggestions) { suggestion in
                    suggestionRow(suggestion)
                    Divider().background(CyberpunkColors.borderSubtle)
                }
            }
        }
    }

    private func suggestionRow(_ suggestion: ProjectFolderSuggestion) -> some View {
        Button {
            if selectedPaths.contains(suggestion.path) {
                selectedPaths.remove(suggestion.path)
            } else {
                selectedPaths.insert(suggestion.path)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: selectedPaths.contains(suggestion.path) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedPaths.contains(suggestion.path) ? CyberpunkColors.accent : CyberpunkColors.textMuted)
                VStack(alignment: .leading, spacing: 3) {
                    Text(suggestion.name)
                        .font(CyberpunkTypography.body(13).weight(.semibold))
                        .foregroundStyle(CyberpunkColors.textPrimary)
                    Text(suggestion.path)
                        .font(CyberpunkTypography.mono(10))
                        .foregroundStyle(CyberpunkColors.textMuted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(suggestion.reasons.joined(separator: " · "))
                        .font(CyberpunkTypography.body(10))
                        .foregroundStyle(CyberpunkColors.textSecondary)
                }
                Spacer()
                Text("\(suggestion.score)")
                    .font(CyberpunkTypography.mono(11))
                    .foregroundStyle(CyberpunkColors.accent)
                    .accessibilityLabel("Match score \(suggestion.score)")
            }
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                selectionControls
                Spacer()
                footerButtons
            }
            VStack(alignment: .leading, spacing: 10) {
                selectionControls
                footerButtons
            }
        }
        .padding(AppLayout.edge)
        .background(CyberpunkColors.bgSecondary)
    }

    private var selectionControls: some View {
        HStack(spacing: 8) {
            Text("\(selectedPaths.count) selected")
                .font(CyberpunkTypography.body(11))
                .foregroundStyle(CyberpunkColors.textSecondary)
            Picker("Tag", selection: $selectedTag) {
                ForEach(ProjectFolderTag.defaults) { tag in
                    Label {
                        Text(tag.name)
                    } icon: {
                        Circle()
                            .fill(ProjectTagStyle.color(for: tag))
                    }
                    .tag(tag)
                }
            }
            .labelsHidden()
            .frame(width: 130)
        }
    }

    private var footerButtons: some View {
        HStack(spacing: 8) {
            Button("Cancel") { dismiss() }
                .buttonStyle(CyberpunkSecondaryButton())
            Button("Add Selected") {
                appState.addSuggestedFolders(
                    paths: Array(selectedPaths),
                    tag: selectedTag,
                    to: projectID
                )
                dismiss()
                Task {
                    await appState.refreshProjectSizes(projectID: projectID)
                    await appState.refreshProjectRepositoryStatuses(
                        projectID: projectID,
                        reportsCompletion: false
                    )
                }
            }
            .buttonStyle(CyberpunkPrimaryButton())
            .disabled(selectedPaths.isEmpty || appState.isSuggestingFolders)
        }
    }

    private func chooseSearchLocations() {
        let panel = NSOpenPanel()
        panel.title = "Choose Project Search Locations"
        panel.prompt = "Use Locations"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.canCreateDirectories = false
        guard panel.runModal() == .OK else { return }
        let paths = appState.projectStore.searchRoots + panel.urls.map(\.path)
        appState.setProjectSearchRoots(paths)
    }

    private func removeSearchRoot(_ path: String) {
        appState.setProjectSearchRoots(
            appState.projectStore.searchRoots.filter { $0 != path }
        )
    }
}
