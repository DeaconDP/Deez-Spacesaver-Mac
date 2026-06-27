import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var newExcludePath = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(CyberpunkTypography.display(18))
                        .foregroundStyle(CyberpunkColors.textPrimary)
                    Text("Scan thresholds, excluded paths, and privacy")
                        .font(CyberpunkTypography.body(12))
                        .foregroundStyle(CyberpunkColors.textMuted)
                }
                Spacer()
            }
            .padding(16)
            .background(CyberpunkColors.bgSecondary)

            if let banner = appState.feedbackBanner {
                CyberpunkFeedbackBanner(banner: banner) {
                    appState.dismissFeedback()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Form {
                Section("Scan Thresholds") {
                    Stepper(
                        "Large file threshold: \(settings.largeFileThresholdMB) MB",
                        value: $settings.largeFileThresholdMB,
                        in: 100...5000,
                        step: 100
                    )
                    Stepper(
                        "Downloads min age: \(settings.downloadsMinAgeDays) days",
                        value: $settings.downloadsMinAgeDays,
                        in: 1...365
                    )
                }

                Section("Excluded Paths") {
                    ForEach(settings.excludePaths, id: \.self) { path in
                        HStack {
                            Text(path)
                                .font(CyberpunkTypography.mono(11))
                            Spacer()
                            Button("Remove") {
                                settings.removeExcludePath(path)
                            }
                            .buttonStyle(CyberpunkSecondaryButton())
                        }
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                    .animation(
                        CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
                        value: settings.excludePaths
                    )

                    HStack {
                        TextField("Path to exclude", text: $newExcludePath)
                        Button("Add") {
                            guard !newExcludePath.isEmpty else { return }
                            settings.addExcludePath(newExcludePath)
                            newExcludePath = ""
                        }
                        .buttonStyle(CyberpunkPrimaryButton())
                    }
                }

                Section("Privacy") {
                    HStack {
                        Text("Full Disk Access")
                        Spacer()
                        Text(appState.hasFullDiskAccess ? "Granted" : "Not granted")
                            .foregroundStyle(appState.hasFullDiskAccess ? CyberpunkColors.accent : CyberpunkColors.accentWarn)
                    }
                    Button("Add Full Disk Access") {
                        appState.beginFullDiskAccessSetup()
                    }
                    .buttonStyle(CyberpunkPrimaryButton())
                    Button {
                        Task { await appState.checkFullDiskAccessAsync() }
                    } label: {
                        CyberpunkLoadingLabel(
                            isLoading: appState.isCheckingFDA,
                            title: appState.isCheckingFDA ? "Checking…" : "Check Again"
                        )
                    }
                    .buttonStyle(CyberpunkSecondaryButton())
                    .disabled(appState.isCheckingFDA)
                    Button("Quit & Reopen") {
                        appState.relaunchApp()
                    }
                    .buttonStyle(CyberpunkSecondaryButton())
                    Button("Show in Finder") {
                        appState.revealAppInFinder()
                    }
                    .buttonStyle(CyberpunkSecondaryButton())
                    if !appState.hasFullDiskAccess {
                        Text("Grant access to the app at the path shown in Finder. After enabling, click Check Again or Quit & Reopen.")
                            .font(CyberpunkTypography.body(11))
                            .foregroundStyle(CyberpunkColors.textMuted)
                    }
                }

                Section("About") {
                    Text("DeezSpacesaver")
                        .font(CyberpunkTypography.display(14))
                    Text("Created by deac.online @ worldbuild.io")
                        .font(CyberpunkTypography.body(12))
                        .foregroundStyle(CyberpunkColors.textMuted)
                    Text("Version 1.0.0")
                        .font(CyberpunkTypography.body(11))
                        .foregroundStyle(CyberpunkColors.textMuted)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(CyberpunkColors.bgPrimary)
        .animation(
            CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
            value: appState.feedbackBanner
        )
    }
}
