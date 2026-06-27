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
        HStack(spacing: 10) {
            Image(systemName: banner.style.icon)
                .foregroundStyle(banner.style.foreground)

            Text(banner.message)
                .font(CyberpunkTypography.body(12))
                .foregroundStyle(CyberpunkColors.textPrimary)
                .lineLimit(2)

            Spacer(minLength: 8)

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
}
