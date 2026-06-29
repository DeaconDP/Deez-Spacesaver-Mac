import SwiftUI

struct CyberpunkPulseDot: View {
    var color: Color = CyberpunkColors.accent
    var size: CGFloat = 6

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .opacity(isPulsing ? 1.0 : 0.4)
            .scaleEffect(isPulsing ? 1.0 : 0.85)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
            .onChange(of: reduceMotion) { _, reduced in
                if reduced {
                    isPulsing = false
                } else {
                    withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
            }
    }
}
