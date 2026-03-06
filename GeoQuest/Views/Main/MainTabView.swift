import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var tabBounce: Int? = nil

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

            Tab("Daily", systemImage: "flame.fill", value: 4) {
                DailyView()
            }

            Tab("Profile", systemImage: "person.crop.circle.fill", value: 5) {
                ProfileView()
            }
        }
        .tint(GQTheme.primary)
        .onChange(of: selectedTab) { _, newTab in
            withAnimation(GQTheme.bouncyQuick) {
                tabBounce = newTab
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                tabBounce = nil
            }
        }
    }
}
