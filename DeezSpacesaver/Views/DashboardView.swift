import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var bannerTransition: AnyTransition {
        .move(edge: .top).combined(with: .opacity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 32) {
                StorageGaugeView(stats: appState.diskStats)

                VStack(alignment: .leading, spacing: 16) {
                    Text("DeezSpacesaver")
                        .font(CyberpunkTypography.display(24))
                        .foregroundStyle(CyberpunkColors.textPrimary)

                    Text("Scan, review, and reclaim disk space safely.")
                        .font(CyberpunkTypography.body(14))
                        .foregroundStyle(CyberpunkColors.textSecondary)

                    HStack(spacing: 12) {
                        StatPill(
                            label: "Available",
                            value: ByteFormatting.string(for: appState.diskStats.availableBytes),
                            accent: CyberpunkColors.accent
                        )
                        StatPill(
                            label: "Used",
                            value: ByteFormatting.string(for: appState.diskStats.usedBytes),
                            accent: CyberpunkColors.accentSecondary
                        )
                        StatPill(
                            label: "Reclaimable",
                            value: ByteFormatting.string(for: appState.scanEngine.totalReclaimableBytes),
                            accent: CyberpunkColors.accentWarn
                        )
                    }

                    HStack(spacing: 12) {
                        Button {
                            appState.scanAll()
                        } label: {
                            CyberpunkLoadingLabel(
                                isLoading: appState.scanEngine.isScanningAll,
                                title: appState.scanEngine.isScanningAll ? "Scanning All…" : "Scan All Categories"
                            )
                        }
                        .buttonStyle(CyberpunkPrimaryButton())
                        .disabled(appState.scanEngine.isScanningAll)

                        Button {
                            Task { await appState.refreshDiskStatsAsync() }
                        } label: {
                            CyberpunkLoadingLabel(
                                isLoading: appState.isRefreshingDiskStats,
                                title: appState.isRefreshingDiskStats ? "Refreshing…" : "Refresh Disk Stats"
                            )
                        }
                        .buttonStyle(CyberpunkSecondaryButton())
                        .disabled(appState.isRefreshingDiskStats)
                    }

                    if !appState.hasFullDiskAccess {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.shield")
                                .foregroundStyle(CyberpunkColors.accentWarn)
                            Text("Grant Full Disk Access for Mail, Messages, and browser cache scanning.")
                                .font(CyberpunkTypography.body(12))
                                .foregroundStyle(CyberpunkColors.textSecondary)
                            Button("Add Full Disk Access") {
                                appState.beginFullDiskAccessSetup()
                            }
                            .buttonStyle(CyberpunkSecondaryButton())
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
                        }
                        .padding(12)
                        .background(CyberpunkColors.accentWarn.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .transition(bannerTransition)
                    }
                }

                Spacer()
            }
            .animation(
                CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
                value: appState.hasFullDiskAccess
            )

            if appState.scanEngine.isScanningAll {
                ScanProgressView(
                    progress: appState.scanEngine.scanAllProgress,
                    message: appState.scanEngine.scanAllMessage ?? "Scanning all categories…",
                    label: "Scan All Progress"
                )
                .transition(.opacity.combined(with: .offset(y: 4)))
            }
        }
        .animation(
            CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
            value: appState.scanEngine.isScanningAll
        )
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(CyberpunkColors.bgPrimary)
    }
}
