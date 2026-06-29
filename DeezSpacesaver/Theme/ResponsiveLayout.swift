import SwiftUI

enum ResponsiveLayout {
    static let windowMinWidth: CGFloat = 720
    static let windowMinHeight: CGFloat = 520

    static let sidebarMinWidth: CGFloat = 240
    static let sidebarIdealWidth: CGFloat = 280
    static let sidebarMaxWidth: CGFloat = 360

    static let compactDetailWidth: CGFloat = 520
    static let mediumDetailWidth: CGFloat = 680

    static func bannerScrollMaxHeight(for detailHeight: CGFloat) -> CGFloat {
        min(220, max(120, detailHeight * 0.28))
    }

    static func dashboardScrollMaxHeight(for detailHeight: CGFloat) -> CGFloat {
        min(400, max(180, detailHeight * 0.45))
    }

    static func showsPathColumn(width: CGFloat) -> Bool {
        width >= mediumDetailWidth
    }

    static func showsModifiedColumn(width: CGFloat) -> Bool {
        width >= compactDetailWidth
    }

    static func showsRiskColumn(width: CGFloat) -> Bool {
        width >= 480
    }
}

private struct DetailWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = 800
}

private struct DetailHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 600
}

extension EnvironmentValues {
    var detailWidth: CGFloat {
        get { self[DetailWidthKey.self] }
        set { self[DetailWidthKey.self] = newValue }
    }

    var detailHeight: CGFloat {
        get { self[DetailHeightKey.self] }
        set { self[DetailHeightKey.self] = newValue }
    }
}

struct DetailSizeReader<Content: View>: View {
    @ViewBuilder let content: (CGSize) -> Content

    var body: some View {
        GeometryReader { geometry in
            content(geometry.size)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
    }
}

/// Backward-compatible width-only reader.
struct DetailWidthReader<Content: View>: View {
    @ViewBuilder let content: (CGFloat) -> Content

    var body: some View {
        DetailSizeReader { size in
            content(size.width)
        }
    }
}

struct ResponsiveBanner<Content: View>: View {
    @ViewBuilder let horizontal: () -> Content
    @ViewBuilder let vertical: () -> Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            horizontal()
            vertical()
        }
    }
}
