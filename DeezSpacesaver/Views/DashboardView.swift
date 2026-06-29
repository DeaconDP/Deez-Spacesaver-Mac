import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var bannerTransition: AnyTransition {
        .move(edge: .top).combined(with: .opacity)
    }

    private var reclaimableBytes: Int64 {
        appState.scanEngine.totalReclaimableBytes
    }

    private var reclaimableAccent: Color {
        ByteFormatting.reclaimableColor(for: reclaimableBytes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            heroSection
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
                .padding(.horizontal, AppLayout.compactEdge)
                .padding(.top, 4)
                .transition(.opacity)
                .animation(
                    CyberpunkAnimation.apply(CyberpunkAnimation.quick, reduceMotion: reduceMotion),
                    value: appState.scanEngine.isScanningAll
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var heroSection: some View {
        DashboardHeroCard {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader
                heroMetric
                storageSection
                metricStrip
                actionToolbar

                if !appState.hasFullDiskAccess {
                    fdaCallout
                        .transition(bannerTransition)
                }
            }
        }
    }

    private var sectionHeader: some View {
        HStack(spacing: 8) {
            Text("Storage Overview")
                .font(CyberpunkTypography.sectionLabel(11))
                .foregroundStyle(CyberpunkColors.textMuted)
                .textCase(.uppercase)
                .tracking(0.6)

            if appState.scanEngine.isScanningAll {
                CyberpunkPulseDot()
                    .transition(.opacity.combined(with: .scale))
            }

            Spacer(minLength: 0)
        }
    }

    private var heroMetric: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Reclaimable from last scan")
                .font(CyberpunkTypography.body(12))
                .foregroundStyle(CyberpunkColors.textSecondary)

            Text(ByteFormatting.string(for: reclaimableBytes))
                .font(CyberpunkTypography.display(30))
                .foregroundStyle(reclaimableAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
                .animation(
                    CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
                    value: reclaimableBytes
                )
        }
    }

    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            StorageCapacityBar(stats: appState.diskStats)

            Text(capacityCaption)
                .font(CyberpunkTypography.body(12))
                .foregroundStyle(CyberpunkColors.textMuted)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
    }

    private var capacityCaption: String {
        let available = ByteFormatting.string(for: appState.diskStats.availableBytes)
        let used = ByteFormatting.string(for: appState.diskStats.usedBytes)
        let total = ByteFormatting.string(for: appState.diskStats.totalBytes)
        return "\(available) available · \(used) used · \(total) total"
    }

    private var metricStrip: some View {
        DashboardMetricStrip(
            available: ByteFormatting.string(for: appState.diskStats.availableBytes),
            used: ByteFormatting.string(for: appState.diskStats.usedBytes),
            reclaimable: ByteFormatting.string(for: reclaimableBytes),
            reclaimableAccent: reclaimableAccent
        )
    }

    private var actionToolbar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                scanAllButton
                refreshButton
            }

            VStack(alignment: .leading, spacing: 8) {
                scanAllButton
                refreshButton
            }
        }
    }

    private var scanAllButton: some View {
        Button {
            appState.scanAll()
        } label: {
            CyberpunkLoadingLabel(
                isLoading: appState.scanEngine.isScanningAll,
                title: appState.scanEngine.isScanningAll ? "Scanning All…" : "Scan All Categories"
            )
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .buttonStyle(CyberpunkPrimaryButton())
        .disabled(appState.scanEngine.isScanningAll)
    }

    private var refreshButton: some View {
        Button {
            Task { await appState.refreshDiskStatsAsync() }
        } label: {
            HStack(spacing: 6) {
                if appState.isRefreshingDiskStats {
                    CyberpunkPulseDot()
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                }
                Text(appState.isRefreshingDiskStats ? "Refreshing…" : "Refresh")
                    .contentTransition(.opacity)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .buttonStyle(CyberpunkSecondaryButton())
        .disabled(appState.isRefreshingDiskStats)
    }

    private var fdaCallout: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 12) {
                fdaMessage
                Spacer(minLength: 8)
                fdaButtons
            }

            VStack(alignment: .leading, spacing: 10) {
                fdaMessage
                fdaButtons
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CyberpunkColors.accentWarn.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(CyberpunkColors.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var fdaMessage: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.shield")
                .foregroundStyle(CyberpunkColors.accentWarn)
            Text("Grant Full Disk Access for Mail, Messages, and browser cache scanning.")
                .font(CyberpunkTypography.body(12))
                .foregroundStyle(CyberpunkColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
    }

    private var fdaButtons: some View {
        HStack(spacing: 8) {
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
    }
}
