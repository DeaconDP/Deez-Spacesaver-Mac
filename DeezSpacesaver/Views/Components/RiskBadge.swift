import SwiftUI

struct RiskBadge: View {
    let level: RiskLevel

    private var color: Color {
        switch level {
        case .safe: return CyberpunkColors.accent
        case .review: return CyberpunkColors.accentWarn
        case .caution: return CyberpunkColors.accentSecondary
        }
    }

    var body: some View {
        Text(level.label)
            .font(CyberpunkTypography.mono(10).weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(color.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
