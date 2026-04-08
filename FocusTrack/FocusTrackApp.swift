import SwiftUI

@main
struct FocusTrackApp: App {
    @StateObject private var dataStore = DataStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
        }
    }
}
