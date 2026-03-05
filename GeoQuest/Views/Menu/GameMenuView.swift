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
        case shop = "Shop"
        case cosmetics = "Cosmetics"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .search: return "magnifyingglass"
            case .leaderboard: return "trophy.fill"
            case .chat: return "bubble.left.and.bubble.right.fill"
            case .avatar: return "person.crop.circle.fill"
            case .friends: return "person.2.fill"
            case .shop: return "bag.fill"
            case .cosmetics: return "sparkles"
            }
        }

        var color: Color {
            switch self {
            case .search: return GQTheme.primary
            case .leaderboard: return GQTheme.gold
            case .chat: return GQTheme.success
            case .avatar: return GQTheme.secondary
            case .friends: return GQTheme.pink
            case .shop: return GQTheme.accent
            case .cosmetics: return GQTheme.teal
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
                            MenuTileButton(section: section) {
                                selectedSection = section
                            }
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
        case .shop:
            ShopView()
        case .cosmetics:
            CosmeticsInventoryView()
        }
    }
}

/// A single menu tile with a textured button background.
private struct MenuTileButton: View {
    let section: GameMenuView.MenuSection
    let action: () -> Void
    @State private var isPressed = false

    private var textureName: String {
        GQGameButton.autoImageName(for: section.color)
    }

    private var pressedTextureName: String {
        GQGameButton.autoPressedImageName(for: section.color)
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Textured background
                if let _ = UIImage(named: textureName) {
                    let imgName = isPressed ? pressedTextureName : textureName
                    Image(imgName)
                        .resizable()
                        .scaledToFill()

                    // Tint overlay for colors without dedicated textures
                    if !GQGameButton.isStandardColor(section.color) {
                        RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                            .fill(section.color.opacity(0.4))
                            .blendMode(.sourceAtop)
                    }
                } else {
                    // Fallback: gradient card
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

                // Icon + label
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 52, height: 52)
                        Image(systemName: section.icon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Text(section.rawValue)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: GQTheme.cornerRadius))
            .offset(y: isPressed ? 2 : 0)
        }
        .buttonStyle(MenuTileButtonStyle(isPressed: $isPressed))
        .shadow(color: section.color.opacity(0.3), radius: 6, x: 0, y: 3)
    }
}

private struct MenuTileButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .onChange(of: configuration.isPressed) { _, pressed in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    isPressed = pressed
                }
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
        case .shop:
            ShopView()
        case .cosmetics:
            CosmeticsInventoryView()
        }
    }
}
