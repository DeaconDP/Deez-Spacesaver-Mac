import Foundation
import SwiftUI

struct DiskStats: Equatable {
    let totalBytes: Int64
    let availableBytes: Int64

    var usedBytes: Int64 { max(0, totalBytes - availableBytes) }

    var usedFraction: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }

    static let empty = DiskStats(totalBytes: 0, availableBytes: 0)
}

enum ByteFormatting {
    private static let oneGB: Int64 = 1_073_741_824
    private static let tenGB: Int64 = 10_737_418_240

    static func string(for bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        return formatter.string(fromByteCount: bytes)
    }

    static func color(for bytes: Int64) -> Color {
        if bytes > tenGB { return CyberpunkColors.sizeHuge }
        if bytes > oneGB { return CyberpunkColors.sizeLarge }
        return CyberpunkColors.accent
    }
}
