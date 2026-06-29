import SwiftUI

enum FeedbackBannerStyle: Equatable {
    case success
    case error
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var foreground: Color {
        switch self {
        case .success: return CyberpunkColors.accent
        case .error: return CyberpunkColors.accentSecondary
        case .info: return CyberpunkColors.textSecondary
        }
    }

    var background: Color {
        switch self {
        case .success: return CyberpunkColors.accentDim
        case .error: return CyberpunkColors.accentSecondaryDim
        case .info: return CyberpunkColors.bgElevated
        }
    }
}

struct FeedbackBanner: Equatable, Identifiable {
    let id: UUID
    let message: String
    let style: FeedbackBannerStyle

    init(message: String, style: FeedbackBannerStyle) {
        self.id = UUID()
        self.message = message
        self.style = style
    }
}

struct CyberpunkFeedbackBanner: View {
    let banner: FeedbackBanner
    var onDismiss: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var bannerTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .move(edge: .top).combined(with: .opacity)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                bannerIcon
                bannerMessage
                Spacer(minLength: 8)
                dismissButton
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    bannerIcon
                    bannerMessage
                }
                dismissButton
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(banner.style.background)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(banner.style.foreground.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .transition(bannerTransition)
    }

    private var bannerIcon: some View {
        Image(systemName: banner.style.icon)
            .foregroundStyle(banner.style.foreground)
    }

    private var bannerMessage: some View {
        Text(banner.message)
            .font(CyberpunkTypography.body(12))
            .foregroundStyle(CyberpunkColors.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)
    }

    @ViewBuilder
    private var dismissButton: some View {
        if let onDismiss {
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(CyberpunkColors.textMuted)
            }
            .buttonStyle(.plain)
        }
    }
}
