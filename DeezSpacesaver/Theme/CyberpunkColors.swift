import SwiftUI

enum CyberpunkColors {
    static let bgPrimary = Color(red: 6/255, green: 8/255, blue: 16/255)
    static let bgSecondary = Color(red: 12/255, green: 17/255, blue: 24/255)
    static let bgElevated = Color(red: 17/255, green: 24/255, blue: 34/255)
    static let bgGlass = Color(red: 17/255, green: 24/255, blue: 34/255).opacity(0.72)

    static let accent = Color(red: 0, green: 229/255, blue: 1)
    static let accentDim = Color(red: 0, green: 229/255, blue: 1).opacity(0.1)
    static let accentGlow = Color(red: 0, green: 229/255, blue: 1).opacity(0.24)

    static let accentSecondary = Color(red: 228/255, green: 0, blue: 143/255)
    static let accentSecondaryDim = Color(red: 228/255, green: 0, blue: 143/255).opacity(0.1)

    static let accentWarn = Color(red: 212/255, green: 160/255, blue: 23/255)
    static let accentTertiary = Color(red: 123/255, green: 92/255, blue: 1)

    static let sizeLarge = Color(red: 255/255, green: 214/255, blue: 0)
    static let sizeHuge = Color(red: 255/255, green: 149/255, blue: 0)

    static let textPrimary = Color(red: 240/255, green: 242/255, blue: 245/255)
    static let textSecondary = Color(red: 168/255, green: 176/255, blue: 188/255)
    static let textMuted = Color(red: 107/255, green: 117/255, blue: 133/255)

    static let borderSubtle = Color.white.opacity(0.07)
    static let borderAccent = Color(red: 0, green: 229/255, blue: 1).opacity(0.32)
}
