import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0
    @State private var tabBounce: Int? = nil
    @State private var showDailyPopup = false
    @State private var dailyPopupChecked = false

    /// Key for UserDefaults — stores the last date the popup was shown.
    private static let lastPopupDateKey = "gq_lastDailyPopupDate"

    var body: some View {
        ZStack {
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

            // Daily streak popup overlay
            if showDailyPopup, let user = appState.currentUser {
                DailyStreakPopupView(
                    currentStreak: user.currentStreak,
                    longestStreak: user.longestStreak,
                    objectives: DailyObjectivePool.todaysObjectives(),
                    onDismiss: {
                        showDailyPopup = false
                    }
                )
                .zIndex(100)
            }
        }
        .onAppear {
            checkAndShowDailyPopup()
        }
    }

    /// Shows the daily popup once per calendar day.
    private func checkAndShowDailyPopup() {
        guard !dailyPopupChecked else { return }
        dailyPopupChecked = true

        let today = Calendar.current.dateKey(for: Date())
        let lastShown = UserDefaults.standard.string(forKey: Self.lastPopupDateKey) ?? ""

        if lastShown != today {
            UserDefaults.standard.set(today, forKey: Self.lastPopupDateKey)
            // Small delay so the map finishes loading first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    showDailyPopup = true
                }
            }
        }
    }
}
