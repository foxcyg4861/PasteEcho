import SwiftUI

@main
struct PasteEchoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("Settings", id: "settings") {
            SettingsView()
                .environmentObject(AppViewModel(dataStore: DataStore.shared))
        }
        .windowResizability(.contentSize)
    }
}
