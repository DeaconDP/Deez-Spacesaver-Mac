import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var contentTransition: AnyTransition {
        .opacity.combined(with: .offset(y: 6))
    }

    private var bannerTransition: AnyTransition {
        .move(edge: .top).combined(with: .opacity)
    }

    var body: some View {
        NavigationSplitView {
            CategoryListView()
                .frame(minWidth: 260)
                .background(CyberpunkColors.bgSecondary)
        } detail: {
            ZStack(alignment: .top) {
                VSplitView {
                    DashboardView()
                        .frame(minHeight: 200)

                    Group {
                        if appState.sidebarSelection == .settings {
                            SettingsView()
                                .transition(contentTransition)
                        } else {
                            ScanResultsView()
                                .transition(contentTransition)
                        }
                    }
                    .frame(minHeight: 200)
                    .animation(
                        CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
                        value: appState.sidebarSelection
                    )
                }

                if appState.sidebarSelection == .settings,
                   let banner = appState.feedbackBanner {
                    CyberpunkFeedbackBanner(banner: banner) {
                        appState.dismissFeedback()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(bannerTransition)
                    .zIndex(1)
                }
            }
            .animation(
                CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
                value: appState.feedbackBanner
            )
        }
        .sheet(isPresented: $appState.showOnboarding) {
            OnboardingView()
                .environmentObject(appState)
        }
        .preferredColorScheme(.dark)
    }
}
