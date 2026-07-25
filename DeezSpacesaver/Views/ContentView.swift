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
                .padding(.horizontal, AppLayout.sidebarHorizontal)
                .padding(.vertical, AppLayout.edge)
                .navigationSplitViewColumnWidth(
                    min: ResponsiveLayout.sidebarMinWidth,
                    ideal: ResponsiveLayout.sidebarIdealWidth,
                    max: ResponsiveLayout.sidebarMaxWidth
                )
        } detail: {
            DetailSizeReader { size in
                let padding = ResponsiveLayout.detailPadding(for: size.width)
                let contentSize = CGSize(
                    width: max(0, size.width - (padding * 2)),
                    height: max(0, size.height - (padding * 2))
                )

                detailPane(size: contentSize)
                    .environment(\.detailWidth, contentSize.width)
                    .environment(\.detailHeight, contentSize.height)
                    .padding(padding)
            }
            .navigationTitle("")
        }
        .frame(
            minWidth: ResponsiveLayout.windowMinWidth,
            maxWidth: .infinity,
            minHeight: ResponsiveLayout.windowMinHeight,
            maxHeight: .infinity
        )
        .background(CyberpunkColors.bgPrimary)
        .sheet(isPresented: $appState.showOnboarding) {
            OnboardingView()
                .environmentObject(appState)
        }
        .preferredColorScheme(.dark)
    }

    private func detailPane(size: CGSize) -> some View {
        ZStack(alignment: .top) {
            Group {
                if appState.sidebarSelection == .appManager {
                    AppManagerView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(contentTransition)
                } else if isProjectSelection {
                    ProjectManagerView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(contentTransition)
                } else {
                    VStack(spacing: 0) {
                        ScrollView {
                            DashboardView()
                                .padding(.horizontal, AppLayout.compactEdge)
                                .padding(.vertical, AppLayout.compactEdge)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxHeight: ResponsiveLayout.dashboardScrollMaxHeight(for: size.height))

                        Divider()
                            .opacity(0.6)
                            .background(CyberpunkColors.borderSubtle)
                            .padding(.top, 4)

                        detailContent
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .layoutPriority(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if appState.sidebarSelection == .settings,
               let banner = appState.feedbackBanner {
                CyberpunkFeedbackBanner(banner: banner) {
                    appState.dismissFeedback()
                }
                .padding(.horizontal, AppLayout.edge)
                .padding(.top, 8)
                .transition(bannerTransition)
                .zIndex(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(
            CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
            value: appState.feedbackBanner
        )
    }

    private var isProjectSelection: Bool {
        switch appState.sidebarSelection {
        case .projects, .project:
            return true
        default:
            return false
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        Group {
            if appState.sidebarSelection == .settings {
                SettingsView()
                    .transition(contentTransition)
            } else {
                ScanResultsView()
                    .transition(contentTransition)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(
            CyberpunkAnimation.apply(CyberpunkAnimation.standard, reduceMotion: reduceMotion),
            value: appState.sidebarSelection
        )
    }
}
