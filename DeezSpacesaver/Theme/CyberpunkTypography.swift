import SwiftUI

enum CyberpunkTypography {
    static func display(_ size: CGFloat = 18) -> Font {
        .custom("Orbitron", size: size).weight(.semibold)
    }

    static func body(_ size: CGFloat = 13) -> Font {
        .system(size: size)
    }

    static func mono(_ size: CGFloat = 11) -> Font {
        .system(size: size, design: .monospaced)
    }
}

struct CyberpunkPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(CyberpunkColors.bgElevated)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(CyberpunkColors.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct CyberpunkPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        CyberpunkPrimaryButtonBody(configuration: configuration)
    }

    private struct CyberpunkPrimaryButtonBody: View {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(\.isEnabled) private var isEnabled
        let configuration: Configuration

        var body: some View {
            configuration.label
                .font(CyberpunkTypography.body(13).weight(.semibold))
                .foregroundStyle(CyberpunkColors.bgPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(CyberpunkColors.accent.opacity(configuration.isPressed ? 0.75 : 1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .shadow(color: CyberpunkColors.accentGlow, radius: configuration.isPressed ? 2 : 6)
                .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.97 : 1))
                .opacity(isEnabled ? 1 : 0.45)
                .animation(
                    CyberpunkAnimation.apply(CyberpunkAnimation.quick, reduceMotion: reduceMotion),
                    value: configuration.isPressed
                )
        }
    }
}

struct CyberpunkSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        CyberpunkSecondaryButtonBody(configuration: configuration)
    }

    private struct CyberpunkSecondaryButtonBody: View {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(\.isEnabled) private var isEnabled
        let configuration: Configuration

        var body: some View {
            configuration.label
                .font(CyberpunkTypography.body(13).weight(.medium))
                .foregroundStyle(CyberpunkColors.accent)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(CyberpunkColors.accentDim)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(CyberpunkColors.borderAccent, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .opacity((configuration.isPressed ? 0.8 : 1) * (isEnabled ? 1 : 0.45))
                .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.97 : 1))
                .animation(
                    CyberpunkAnimation.apply(CyberpunkAnimation.quick, reduceMotion: reduceMotion),
                    value: configuration.isPressed
                )
        }
    }
}

struct CyberpunkLoadingLabel: View {
    let isLoading: Bool
    let title: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.65)
                    .transition(.opacity.combined(with: .scale))
            }
            Text(title)
                .contentTransition(.opacity)
        }
        .animation(
            CyberpunkAnimation.apply(CyberpunkAnimation.quick, reduceMotion: reduceMotion),
            value: isLoading
        )
    }
}

extension View {
    func cyberpunkPanel() -> some View {
        modifier(CyberpunkPanel())
    }
}
