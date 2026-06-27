import SwiftUI

struct CategoryInfoPanel: View {
    let category: CleanupCategory
    let hasFDA: Bool
    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                Text(category.education.overview)
                    .font(CyberpunkTypography.body(12))
                    .foregroundStyle(CyberpunkColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                infoRow(label: "Finds", value: category.education.whatItFinds)
                infoRow(label: "Cleanup", value: category.education.onCleanup)

                if let considerations = category.education.considerations {
                    infoRow(label: "Note", value: considerations)
                }

                if category.requiresFullDiskAccess && !hasFDA {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(CyberpunkColors.accentWarn)
                        Text("Full Disk Access required to scan this category.")
                            .font(CyberpunkTypography.body(11))
                            .foregroundStyle(CyberpunkColors.accentWarn)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.top, 8)
        } label: {
            Text("About this cleanup")
                .font(CyberpunkTypography.body(12).weight(.medium))
                .foregroundStyle(CyberpunkColors.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(CyberpunkColors.bgElevated.opacity(0.5))
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(label):")
                .font(CyberpunkTypography.body(11).weight(.semibold))
                .foregroundStyle(CyberpunkColors.accent)
                .frame(width: 58, alignment: .leading)
            Text(value)
                .font(CyberpunkTypography.body(11))
                .foregroundStyle(CyberpunkColors.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
