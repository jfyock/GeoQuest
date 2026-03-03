import SwiftUI

struct GameMenuView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: MenuSection? = nil
    @State private var appeared = false

    enum MenuSection: String, CaseIterable, Identifiable {
        case search = "Search Quests"
        case leaderboard = "Leaderboard"
        case chat = "Global Chat"
        case avatar = "Customize"
        case friends = "Friends"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .search: return "magnifyingglass"
            case .leaderboard: return "trophy.fill"
            case .chat: return "bubble.left.and.bubble.right.fill"
            case .avatar: return "person.crop.circle.fill"
            case .friends: return "person.2.fill"
            }
        }

        var color: Color {
            switch self {
            case .search: return GQTheme.primary
            case .leaderboard: return GQTheme.gold
            case .chat: return GQTheme.success
            case .avatar: return GQTheme.secondary
            case .friends: return GQTheme.pink
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: GQTheme.paddingLarge) {
                    // Player summary card
                    if let user = appState.currentUser {
                        HStack(spacing: 16) {
                            AvatarPreviewView(config: user.avatarConfig, size: 56)
                                .shadow(color: GQTheme.secondary.opacity(0.3), radius: 8)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(user.displayName)
                                    .font(GQTheme.headlineFont)
                                HStack(spacing: 10) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "trophy.fill")
                                            .foregroundStyle(GQTheme.gold)
                                        Text("\(user.totalScore)")
                                            .font(.system(.caption, design: .rounded, weight: .bold))
                                    }
                                    HStack(spacing: 4) {
                                        Image(systemName: "flame.fill")
                                            .foregroundStyle(GQTheme.accent)
                                        Text("\(user.questsCompleted) solved")
                                            .font(.system(.caption, design: .rounded, weight: .bold))
                                    }
                                }
                                .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(GQTheme.paddingMedium)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                                    .fill(GQTheme.cardBackground)
                                RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                                    .stroke(GQTheme.secondary.opacity(0.15), lineWidth: 2)
                            }
                        )
                        .gqShadow()
                        .scaleEffect(appeared ? 1 : 0.9)
                        .opacity(appeared ? 1 : 0)
                    }

                    // Menu grid
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                        ForEach(Array(MenuSection.allCases.enumerated()), id: \.element.id) { index, section in
                            Button {
                                selectedSection = section
                            } label: {
                                VStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(section.color.opacity(0.15))
                                            .frame(width: 52, height: 52)
                                        Image(systemName: section.icon)
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundStyle(section.color)
                                    }

                                    Text(section.rawValue)
                                        .font(.system(.caption, design: .rounded, weight: .bold))
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                                            .fill(GQTheme.cardBackground)
                                        RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                                            .stroke(section.color.opacity(0.2), lineWidth: 2)
                                        RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                                            .fill(
                                                LinearGradient(
                                                    colors: [section.color.opacity(0.08), .clear],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                    }
                                )
                                .gqShadow()
                            }
                            .buttonStyle(CartoonButtonStyle())
                            .scaleEffect(appeared ? 1 : 0.5)
                            .opacity(appeared ? 1 : 0)
                            .animation(GQTheme.bouncyHeavy.delay(Double(index) * 0.06), value: appeared)
                        }
                    }
                }
                .padding(GQTheme.paddingLarge)
            }
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .gqDismissToolbar(dismiss: dismiss)
            .sheet(item: $selectedSection) { section in
                SubMenuSheet(section: section) {
                    selectedSection = nil
                }
                .environment(appState)
            }
        }
        .gqMenuSheet()
        .onAppear {
            withAnimation(GQTheme.bouncyHeavy) {
                appeared = true
            }
        }
    }

    @ViewBuilder
    private func sectionView(for section: MenuSection) -> some View {
        switch section {
        case .search:
            QuestListView()
                .navigationTitle("Search Quests")
        case .leaderboard:
            LeaderboardView()
        case .chat:
            ChatView()
        case .avatar:
            AvatarCustomizationView()
        case .friends:
            FriendsView()
        }
    }
}

private struct SubMenuSheet: View {
    let section: GameMenuView.MenuSection
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        content
            .gqMenuSheet()
    }

    @ViewBuilder
    private var content: some View {
        switch section {
        case .search:
            NavigationStack {
                QuestListView()
                    .navigationTitle("Search Quests")
                    .gqDismissToolbar(dismiss: dismiss)
            }
        case .leaderboard:
            LeaderboardView()
        case .chat:
            ChatView()
        case .avatar:
            NavigationStack {
                AvatarCustomizationView()
                    .gqDismissToolbar(dismiss: dismiss)
            }
        case .friends:
            FriendsView()
        }
    }
}
