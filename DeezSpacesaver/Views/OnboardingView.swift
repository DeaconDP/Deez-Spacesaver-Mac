import SwiftUI

enum OnboardingStep {
    case welcome
    case fullDiskAccess
}

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step: OnboardingStep = .welcome
    @State private var fdaCheckStatus: String?

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(x: 20)),
            removal: .opacity.combined(with: .offset(x: -20))
        )
    }

    var body: some View {
        Group {
            switch step {
            case .welcome:
                welcomeContent
                    .transition(stepTransition)
            case .fullDiskAccess:
                fdaContent
                    .transition(stepTransition)
            }
        }
        .animation(
            CyberpunkAnimation.apply(CyberpunkAnimation.emphasis, reduceMotion: reduceMotion),
            value: step
        )
        .padding(32)
        .frame(width: 520)
        .background(CyberpunkColors.bgPrimary)
    }

    private var welcomeContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "externaldrive.fill.badge.checkmark")
                .font(.system(size: 48))
                .foregroundStyle(CyberpunkColors.accent)

            Text("Welcome to DeezSpacesaver")
                .font(CyberpunkTypography.display(22))
                .foregroundStyle(CyberpunkColors.textPrimary)

            Text("Reclaim disk space safely in three steps:")
                .font(CyberpunkTypography.body(14))
                .foregroundStyle(CyberpunkColors.textSecondary)

            VStack(alignment: .leading, spacing: 12) {
                StaggeredOnboardingStep(number: "1", title: "Scan", detail: "Pick a category and find reclaimable files", delay: 0.05)
                StaggeredOnboardingStep(number: "2", title: "Review", detail: "Check the list before anything is removed", delay: 0.15)
                StaggeredOnboardingStep(number: "3", title: "Move to Trash", detail: "Items go to Trash — empty Trash when ready", delay: 0.25)
            }
            .padding(16)
            .cyberpunkPanel()

            Text("Nothing is permanently deleted until you empty Trash yourself.")
                .font(CyberpunkTypography.body(12))
                .foregroundStyle(CyberpunkColors.textMuted)
                .multilineTextAlignment(.center)

            Button("Get Started") {
                if let animation = CyberpunkAnimation.apply(CyberpunkAnimation.emphasis, reduceMotion: reduceMotion) {
                    withAnimation(animation) {
                        step = .fullDiskAccess
                    }
                } else {
                    step = .fullDiskAccess
                }
            }
            .buttonStyle(CyberpunkPrimaryButton())
        }
    }

    private var fdaContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(CyberpunkColors.accent)

            Text("Full Disk Access")
                .font(CyberpunkTypography.display(22))
                .foregroundStyle(CyberpunkColors.textPrimary)

            Text("Optional but recommended. Add the exact app shown below — local builds live in dist/, not Applications.")
                .font(CyberpunkTypography.body(14))
                .foregroundStyle(CyberpunkColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            VStack(alignment: .leading, spacing: 8) {
                step("1", "Click Add Full Disk Access below", "Opens System Settings and reveals the app in Finder")
                step("2", "Click the + button at the bottom of the Full Disk Access list")
                step("3", "Select DeezSpacesaver in Finder", "We highlight it for you")
                step("4", "Toggle it on, return here, and click Check Again", "If still not detected, use Quit & Reopen")
            }
            .padding(16)
            .cyberpunkPanel()

            Text(appState.appBundlePath)
                .font(CyberpunkTypography.mono(10))
                .foregroundStyle(CyberpunkColors.textMuted)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            Text("You can move this window to see System Settings behind it.")
                .font(CyberpunkTypography.body(11))
                .foregroundStyle(CyberpunkColors.textMuted)
                .multilineTextAlignment(.center)

            if let fdaCheckStatus {
                Text(fdaCheckStatus)
                    .font(CyberpunkTypography.body(12))
                    .foregroundStyle(appState.hasFullDiskAccess ? CyberpunkColors.accent : CyberpunkColors.accentWarn)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }

            VStack(spacing: 12) {
                Button("Add Full Disk Access") {
                    appState.beginFullDiskAccessSetup()
                }
                .buttonStyle(CyberpunkPrimaryButton())

                Button("Check Again") {
                    appState.refreshFullDiskAccess()
                    if appState.hasFullDiskAccess {
                        fdaCheckStatus = "Full Disk Access granted."
                        finishOnboarding()
                    } else {
                        fdaCheckStatus = "Still not detected — try Quit & Reopen after enabling in System Settings."
                    }
                }
                .buttonStyle(CyberpunkSecondaryButton())

                Button("Quit & Reopen") {
                    appState.relaunchApp()
                }
                .buttonStyle(CyberpunkSecondaryButton())

                Button("Continue Without") {
                    finishOnboarding()
                }
                .buttonStyle(CyberpunkSecondaryButton())
            }
        }
    }

    private func step(_ number: String, _ title: String, _ detail: String? = nil) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(CyberpunkTypography.mono(12))
                .foregroundStyle(CyberpunkColors.accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(CyberpunkTypography.body(13).weight(.medium))
                    .foregroundStyle(CyberpunkColors.textPrimary)
                if let detail {
                    Text(detail)
                        .font(CyberpunkTypography.body(11))
                        .foregroundStyle(CyberpunkColors.textMuted)
                }
            }
        }
    }

    private func finishOnboarding() {
        appState.dismissOnboarding(markSeen: true)
        dismiss()
    }
}

private struct StaggeredOnboardingStep: View {
    let number: String
    let title: String
    let detail: String?
    let delay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visible = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(CyberpunkTypography.mono(12))
                .foregroundStyle(CyberpunkColors.accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(CyberpunkTypography.body(13).weight(.medium))
                    .foregroundStyle(CyberpunkColors.textPrimary)
                if let detail {
                    Text(detail)
                        .font(CyberpunkTypography.body(11))
                        .foregroundStyle(CyberpunkColors.textMuted)
                }
            }
        }
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 8)
        .onAppear {
            if reduceMotion {
                visible = true
            } else {
                withAnimation(CyberpunkAnimation.standard.delay(delay)) {
                    visible = true
                }
            }
        }
    }
}
