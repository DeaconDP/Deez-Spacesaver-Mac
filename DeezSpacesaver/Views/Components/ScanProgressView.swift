import SwiftUI

struct ScanProgressView: View {
    let progress: Double?
    let message: String
    var label: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulseGlow = false

    var body: some View {
        VStack(spacing: 12) {
            if let label {
                Text(label)
                    .font(CyberpunkTypography.body(13).weight(.medium))
                    .foregroundStyle(CyberpunkColors.textSecondary)
            }

            if let progress {
                ProgressView(value: progress)
                    .progressViewStyle(CyberpunkProgressStyle(pulseGlow: pulseGlow && !reduceMotion))
            } else {
                CyberpunkPulseDot(size: 8)
            }

            Text(message)
                .font(CyberpunkTypography.mono(11))
                .foregroundStyle(CyberpunkColors.textMuted)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .animation(
                    CyberpunkAnimation.apply(CyberpunkAnimation.quick, reduceMotion: reduceMotion),
                    value: message
                )
        }
        .padding(.horizontal, 24)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseGlow = true
            }
        }
    }
}

struct CyberpunkProgressStyle: ProgressViewStyle {
    var pulseGlow: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(CyberpunkColors.bgSecondary)
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 3)
                    .fill(CyberpunkColors.accent)
                    .frame(
                        width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0),
                        height: 6
                    )
                    .shadow(
                        color: pulseGlow ? CyberpunkColors.accentGlow : .clear,
                        radius: pulseGlow ? 6 : 0
                    )
            }
        }
        .frame(height: 6)
    }
}
