import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Explore", systemImage: "map.fill", value: 0) {
                MapContainerView()
            }

            Tab("Create", systemImage: "plus.circle.fill", value: 1) {
                QuestCreationView()
            }

            Tab("Ranks", systemImage: "trophy.fill", value: 2) {
                LeaderboardView()
            }

            Tab("Chat", systemImage: "bubble.left.and.bubble.right.fill", value: 3) {
                ChatView()
            }

            Tab("Profile", systemImage: "person.crop.circle.fill", value: 4) {
                ProfileView()
            }
        }
        .tint(GQTheme.primary)
    }
}
