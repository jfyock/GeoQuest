import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: ProfileViewModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: GQTheme.paddingLarge) {
                    if let user = appState.currentUser {
                        profileHeader(user: user)
                        statsGrid(user: user)
                        navigationLinks
                        createdQuestsList
                    } else {
                        GQLoadingIndicator(message: "Loading profile...")
                    }
                }
                .padding(GQTheme.paddingLarge)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ProfileViewModel(questService: appState.questService)
            }
            if let userId = appState.currentUser?.id {
                Task { await viewModel?.loadCreatedQuests(userId: userId) }
            }
        }
    }

    // MARK: - Header

    private func profileHeader(user: GQUser) -> some View {
        VStack(spacing: 14) {
            AvatarPreviewView(config: user.avatarConfig, size: 110)
                .shadow(color: GQTheme.secondary.opacity(0.3), radius: 12)

            Text(user.displayName)
                .font(GQTheme.title2Font)

            if !user.city.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(GQTheme.primary)
                    Text(user.city)
                        .foregroundStyle(.secondary)
                }
                .font(GQTheme.captionFont)
            }

            Text("Joined \(user.joinedAt.shortFormatted)")
                .font(GQTheme.caption2Font)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Stats

    private func statsGrid(user: GQUser) -> some View {
        HStack(spacing: 16) {
            statCard(value: "\(user.totalScore)", label: "Score", icon: "trophy.fill", color: .yellow)
            statCard(value: "\(user.questsCompleted)", label: "Solved", icon: "checkmark.circle.fill", color: GQTheme.success)
            statCard(value: "\(user.questsCreated)", label: "Created", icon: "plus.circle.fill", color: GQTheme.accent)
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
            Text(label)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(GQTheme.paddingMedium)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                    .fill(GQTheme.cardBackground)
                RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                    .stroke(color.opacity(0.15), lineWidth: 2)
                RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.06), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .gqShadow()
    }

    // MARK: - Nav Links

    @State private var showFriends = false

    private var navigationLinks: some View {
        VStack(spacing: 10) {
            Button {
                showFriends = true
            } label: {
                navRow(icon: "person.2.fill", title: "Friends", color: GQTheme.pink)
            }
            .buttonStyle(BouncyScaleStyle())
            .sheet(isPresented: $showFriends) {
                FriendsView()
                    .environment(appState)
            }

            NavigationLink {
                AvatarCustomizationView()
            } label: {
                navRow(icon: "person.crop.circle.fill", title: "Customize Avatar", color: GQTheme.accent)
            }
            .buttonStyle(BouncyScaleStyle())

            NavigationLink {
                SettingsView()
            } label: {
                navRow(icon: "gearshape.fill", title: "Settings", color: .gray)
            }
            .buttonStyle(BouncyScaleStyle())
        }
    }

    private func navRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(color)
            }

            Text(title)
                .font(GQTheme.bodyFont)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .padding(GQTheme.paddingMedium)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                    .fill(GQTheme.cardBackground)
                RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                    .stroke(color.opacity(0.1), lineWidth: 1.5)
            }
        )
    }

    // MARK: - Created Quests

    @ViewBuilder
    private var createdQuestsList: some View {
        if let viewModel {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Quests")
                    .font(GQTheme.headlineFont)

                if viewModel.isLoadingQuests {
                    GQLoadingIndicator(message: "Loading quests...")
                } else if viewModel.createdQuests.isEmpty {
                    GQCard {
                        HStack {
                            Image(systemName: "map.fill")
                                .foregroundStyle(.secondary)
                            Text("No quests created yet. Go create your first!")
                                .font(GQTheme.bodyFont)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    ForEach(viewModel.createdQuests) { quest in
                        questRow(quest: quest)
                    }
                }
            }
        }
    }

    private func questRow(quest: Quest) -> some View {
        HStack(spacing: 12) {
            Image(systemName: quest.iconName)
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: quest.iconColor))
                .frame(width: 36, height: 36)
                .background(Color(hex: quest.iconColor).opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(quest.title)
                    .font(GQTheme.bodyFont.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text("\(quest.totalCompletions) completions")
                    if quest.totalRatings > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text(String(format: "%.1f", quest.averageRating))
                        }
                    }
                }
                .font(GQTheme.caption2Font)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .gqCard()
    }
}
