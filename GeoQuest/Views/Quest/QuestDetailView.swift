import SwiftUI
import CoreLocation

struct QuestDetailView: View {
    let questId: String
    var mapViewModel: MapViewModel?
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: QuestDetailViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    questContent(viewModel: viewModel)
                } else {
                    GQLoadingIndicator()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                let vm = QuestDetailViewModel(
                    questService: appState.questService,
                    userService: appState.userService,
                    leaderboardService: appState.leaderboardService
                )
                viewModel = vm
                Task {
                    await vm.loadQuest(id: questId, userId: appState.currentUser?.id ?? "")
                }
            }
        }
    }

    @ViewBuilder
    private func questContent(viewModel: QuestDetailViewModel) -> some View {
        switch viewModel.state {
        case .loading:
            GQLoadingIndicator(message: "Loading quest...")

        case .error(let message):
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(GQTheme.warning)
                Text(message)
                    .font(GQTheme.bodyFont)
                    .foregroundStyle(.secondary)
            }

        case .loaded:
            if let quest = viewModel.quest {
                switch viewModel.playState {
                case .notStarted:
                    questInfoView(quest: quest, viewModel: viewModel)
                case .playing, .enteringCode:
                    QuestPlayView(viewModel: viewModel, quest: quest)
                case .completed:
                    QuestCompletionView(viewModel: viewModel, quest: quest)
                }
            }
        }
    }

    private func questInfoView(quest: Quest, viewModel: QuestDetailViewModel) -> some View {
        ScrollView {
            VStack(spacing: GQTheme.paddingLarge) {
                // Quest icon
                ZStack {
                    Circle()
                        .fill(Color(hex: quest.iconColor).opacity(0.15))
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(Color(hex: quest.iconColor))
                        .frame(width: 72, height: 72)
                    Image(systemName: quest.iconName)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.white)
                }

                // Title and creator
                VStack(spacing: 6) {
                    Text(quest.title)
                        .font(GQTheme.title2Font)
                        .multilineTextAlignment(.center)

                    Text("by \(quest.creatorDisplayName)")
                        .font(GQTheme.captionFont)
                        .foregroundStyle(.secondary)
                }

                // Stats row
                HStack(spacing: 20) {
                    statBadge(icon: quest.difficulty.iconName, label: quest.difficulty.displayName, color: difficultyColor(quest.difficulty))
                    statBadge(icon: "person.2.fill", label: "\(quest.totalCompletions)", color: .blue)
                    if quest.totalRatings > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text(String(format: "%.1f", quest.averageRating))
                        }
                        .font(GQTheme.captionFont.weight(.semibold))
                    }
                    statBadge(icon: "number", label: "\(quest.steps.count) steps", color: .purple)
                }

                // Description
                GQCard {
                    Text(quest.description)
                        .font(GQTheme.bodyFont)
                        .foregroundStyle(.secondary)
                }

                // Distance from player
                if let userLocation = appState.locationService.currentLocation {
                    let questLocation = CLLocation(latitude: quest.latitude, longitude: quest.longitude)
                    let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                    let distance = userLoc.distance(from: questLocation)

                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .foregroundStyle(GQTheme.primary)
                        Text(formatDistance(distance))
                            .font(GQTheme.bodyFont)
                            .foregroundStyle(.secondary)
                    }
                }

                // Points value
                GQCard {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(.yellow)
                        Text("\(quest.pointValue) base points")
                            .font(GQTheme.headlineFont)
                        Spacer()
                    }
                }

                // Action button
                if viewModel.isCompletedByUser {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(GQTheme.success)
                        Text("Quest Completed!")
                            .font(GQTheme.headlineFont)
                            .foregroundStyle(GQTheme.success)
                    }
                } else {
                    GQButton(title: "Start Quest", icon: "play.fill", color: GQTheme.accent) {
                        viewModel.startQuest()
                    }
                }
            }
            .padding(GQTheme.paddingLarge)
        }
    }

    private func statBadge(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(label)
        }
        .font(GQTheme.captionFont.weight(.semibold))
    }

    private func difficultyColor(_ difficulty: QuestDifficulty) -> Color {
        switch difficulty {
        case .easy: return GQTheme.easyColor
        case .medium: return GQTheme.mediumColor
        case .hard: return GQTheme.hardColor
        case .expert: return GQTheme.expertColor
        }
    }

    private func formatDistance(_ meters: CLLocationDistance) -> String {
        if meters < 1000 {
            return "\(Int(meters))m away"
        } else {
            return String(format: "%.1f km away", meters / 1000)
        }
    }
}
