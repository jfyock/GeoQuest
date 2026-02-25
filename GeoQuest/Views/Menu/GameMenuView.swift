import SwiftUI

struct GameMenuView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: MenuSection? = nil

    enum MenuSection: String, CaseIterable, Identifiable {
        case search = "Search Quests"
        case leaderboard = "Leaderboard"
        case chat = "Global Chat"
        case avatar = "Customize Avatar"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .search: return "magnifyingglass"
            case .leaderboard: return "trophy.fill"
            case .chat: return "bubble.left.and.bubble.right.fill"
            case .avatar: return "person.crop.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .search: return .blue
            case .leaderboard: return .yellow
            case .chat: return .green
            case .avatar: return .purple
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: GQTheme.paddingMedium) {
                // Player summary
                if let user = appState.currentUser {
                    HStack(spacing: 14) {
                        AvatarPreviewView(config: user.avatarConfig, size: 50)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.displayName)
                                .font(GQTheme.headlineFont)
                            HStack(spacing: 8) {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(.yellow)
                                Text("\(user.totalScore) pts")
                                    .font(GQTheme.captionFont)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(GQTheme.paddingMedium)
                    .background(GQTheme.cardBackground, in: RoundedRectangle(cornerRadius: GQTheme.cornerRadius))
                }

                // Menu grid
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(MenuSection.allCases) { section in
                        Button {
                            selectedSection = section
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: section.icon)
                                    .font(.system(size: 28))
                                    .foregroundStyle(section.color)

                                Text(section.rawValue)
                                    .font(GQTheme.captionFont.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .background(section.color.opacity(0.1), in: RoundedRectangle(cornerRadius: GQTheme.cornerRadius))
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                }

                Spacer()
            }
            .padding(GQTheme.paddingLarge)
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(item: $selectedSection) { section in
                NavigationStack {
                    sectionView(for: section)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { selectedSection = nil }
                            }
                        }
                }
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
        }
    }
}
