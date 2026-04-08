import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        if !dataStore.hasCompletedOnboarding || dataStore.children.isEmpty {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}

// MARK: - Main Tab Container

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home",      systemImage: "house.fill") }

            ExerciseListView()
                .tabItem { Label("Exercises", systemImage: "pencil.circle.fill") }

            ReportsView()
                .tabItem { Label("Reports",   systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings",  systemImage: "gearshape.fill") }
        }
        .accentColor(.blue)
    }
}
