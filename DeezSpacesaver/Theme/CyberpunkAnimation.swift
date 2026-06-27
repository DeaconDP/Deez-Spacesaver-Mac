import SwiftUI

enum CyberpunkAnimation {
    static let quick = Animation.easeOut(duration: 0.15)
    static let standard = Animation.spring(response: 0.28, dampingFraction: 0.82)
    static let emphasis = Animation.spring(response: 0.45, dampingFraction: 0.78)

    static func apply(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }
}

extension View {
    func cyberpunkTransition(_ transition: AnyTransition = .opacity.combined(with: .offset(y: 6))) -> some View {
        self.transition(transition)
    }
}
