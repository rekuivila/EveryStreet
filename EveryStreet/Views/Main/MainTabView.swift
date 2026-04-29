import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = Tab.map

    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .tabItem { Label("Map", systemImage: "map.fill") }
                .tag(Tab.map)

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(Tab.stats)

            LeaderboardView()
                .tabItem { Label("Leaderboard", systemImage: "trophy.fill") }
                .tag(Tab.leaderboard)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(Tab.profile)
        }
        .tint(AppConstants.accentColor)
    }

    private enum Tab {
        case map, stats, leaderboard, profile
    }
}
