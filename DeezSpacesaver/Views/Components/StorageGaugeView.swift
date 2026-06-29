import SwiftUI

struct DashboardHeroCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(AppLayout.content)
            .background {
                ZStack(alignment: .top) {
                    CyberpunkColors.bgElevated
                    CyberpunkColors.bgGlass
                    CyberpunkColors.cardTopAccent
                        .frame(height: 2)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: CyberpunkColors.cardRadius)
                    .stroke(CyberpunkColors.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: CyberpunkColors.cardRadius))
    }
}

struct StorageCapacityBar: View {
    let stats: DiskStats

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var displayedFraction: Double = 0

    private var percentUsed: Int {
        Int(displayedFraction * 100)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: CyberpunkColors.barHeight / 2)
                    .fill(CyberpunkColors.bgSecondary)
                    .frame(height: CyberpunkColors.barHeight)

                RoundedRectangle(cornerRadius: CyberpunkColors.barHeight / 2)
                    .fill(CyberpunkColors.accentGradient)
                    .frame(
                        width: max(0, geometry.size.width * CGFloat(displayedFraction)),
                        height: CyberpunkColors.barHeight
                    )
                    .shadow(color: CyberpunkColors.accentGlow, radius: 4)
            }
        }
        .frame(height: CyberpunkColors.barHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(percentUsed) percent of disk used")
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

struct DashboardMetric: View {
    let label: String
    let value: String
    let accent: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(CyberpunkTypography.sectionLabel(10))
                .foregroundStyle(CyberpunkColors.textMuted)
                .textCase(.uppercase)
                .tracking(0.4)
                .lineLimit(1)
            Text(value)
                .font(CyberpunkTypography.mono(14))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(
            CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
            value: value
        )
    }
}

struct DashboardMetricStrip: View {
    let available: String
    let used: String
    let reclaimable: String
    let reclaimableAccent: Color

    var body: some View {
        ViewThatFits(in: .horizontal) {
            metricRow
            metricStack
        }
    }

    private var metricRow: some View {
        HStack(spacing: 0) {
            DashboardMetric(label: "Available", value: available, accent: CyberpunkColors.accent)
            metricDivider
            DashboardMetric(label: "Used", value: used, accent: CyberpunkColors.accentSecondary)
            metricDivider
            DashboardMetric(label: "Reclaimable", value: reclaimable, accent: reclaimableAccent)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(CyberpunkColors.bgSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: CyberpunkColors.controlRadius))
    }

    private var metricStack: some View {
        VStack(spacing: 0) {
            DashboardMetric(label: "Available", value: available, accent: CyberpunkColors.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            metricDividerHorizontal
            DashboardMetric(label: "Used", value: used, accent: CyberpunkColors.accentSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            metricDividerHorizontal
            DashboardMetric(label: "Reclaimable", value: reclaimable, accent: reclaimableAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
        }
        .background(CyberpunkColors.bgSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: CyberpunkColors.controlRadius))
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(CyberpunkColors.borderSubtle)
            .frame(width: 1)
            .padding(.vertical, 8)
    }

    private var metricDividerHorizontal: some View {
        Rectangle()
            .fill(CyberpunkColors.borderSubtle)
            .frame(height: 1)
    }
}
