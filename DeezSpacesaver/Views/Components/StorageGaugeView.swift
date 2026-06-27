import SwiftUI

struct StorageGaugeView: View {
    let stats: DiskStats
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayedFraction: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(CyberpunkColors.bgSecondary, lineWidth: 14)
            Circle()
                .trim(from: 0, to: displayedFraction)
                .stroke(
                    AngularGradient(
                        colors: [CyberpunkColors.accent, CyberpunkColors.accentSecondary, CyberpunkColors.accent],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: CyberpunkColors.accentGlow, radius: 8)

            VStack(spacing: 4) {
                Text("\(Int(displayedFraction * 100))%")
                    .font(CyberpunkTypography.display(28))
                    .foregroundStyle(CyberpunkColors.textPrimary)
                    .contentTransition(.numericText())
                Text("used")
                    .font(CyberpunkTypography.body(12))
                    .foregroundStyle(CyberpunkColors.textMuted)
            }
        }
        .frame(width: 160, height: 160)
        .onAppear {
            setDisplayedFraction(stats.usedFraction, animated: false)
        }
        .onChange(of: stats.usedFraction) { _, newValue in
            setDisplayedFraction(newValue, animated: true)
        }
        .animation(
            CyberpunkAnimation.apply(CyberpunkAnimation.emphasis, reduceMotion: reduceMotion),
            value: displayedFraction
        )
    }

    private func setDisplayedFraction(_ value: Double, animated: Bool) {
        if animated, let animation = CyberpunkAnimation.apply(CyberpunkAnimation.emphasis, reduceMotion: reduceMotion) {
            withAnimation(animation) {
                displayedFraction = value
            }
        } else {
            displayedFraction = value
        }
    }
}

struct StatPill: View {
    let label: String
    let value: String
    let accent: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(CyberpunkTypography.body(11))
                .foregroundStyle(CyberpunkColors.textMuted)
            Text(value)
                .font(CyberpunkTypography.mono(14))
                .foregroundStyle(accent)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(CyberpunkColors.bgSecondary)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(CyberpunkColors.borderSubtle, lineWidth: 1)
        )
        .animation(
            CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
            value: value
        )
    }
}
