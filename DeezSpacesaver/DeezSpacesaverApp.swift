import SwiftUI

@main
struct DeezSpacesaverApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .defaultSize(width: 1100, height: 750)
        .windowResizability(.contentMinSize)
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
