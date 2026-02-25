import SwiftUI
import CoreLocation

struct QuestListView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: SearchViewModel?
    @State private var selectedQuestId: String?

    var body: some View {
        Group {
            if let viewModel {
                searchContent(viewModel: viewModel)
            } else {
                GQLoadingIndicator()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = SearchViewModel(questService: appState.questService)
                if let location = appState.locationService.currentLocation {
                    Task { await viewModel?.loadNearby(location: location) }
                }
            }
        }
    }

    private func searchContent(viewModel: SearchViewModel) -> some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search quests...", text: Binding(
                    get: { viewModel.searchText },
                    set: { viewModel.searchText = $0 }
                ))
                .font(GQTheme.bodyFont)
                .submitLabel(.search)
                .onSubmit {
                    Task { await viewModel.search() }
                }

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.clear()
                        if let location = appState.locationService.currentLocation {
                            Task { await viewModel.loadNearby(location: location) }
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(GQTheme.cardBackground, in: RoundedRectangle(cornerRadius: GQTheme.cornerRadiusSmall))
            .padding(.horizontal, GQTheme.paddingMedium)
            .padding(.vertical, GQTheme.paddingSmall)

            // Results
            if viewModel.isSearching {
                Spacer()
                GQLoadingIndicator(message: "Searching...")
                Spacer()
            } else if viewModel.results.isEmpty && viewModel.hasSearched {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("No quests found")
                        .font(GQTheme.bodyFont)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        if !viewModel.hasSearched {
                            Text("Nearby Quests")
                                .font(GQTheme.headlineFont)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }

                        ForEach(viewModel.results) { quest in
                            questRow(quest: quest)
                                .onTapGesture {
                                    selectedQuestId = quest.id
                                }
                        }
                    }
                    .padding(.horizontal, GQTheme.paddingMedium)
                    .padding(.vertical, GQTheme.paddingSmall)
                }
            }
        }
        .sheet(item: $selectedQuestId) { questId in
            QuestDetailView(questId: questId)
        }
    }

    private func questRow(quest: Quest) -> some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: quest.iconColor).opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: quest.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: quest.iconColor))
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(quest.title)
                    .font(GQTheme.bodyFont.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Difficulty
                    HStack(spacing: 3) {
                        Image(systemName: quest.difficulty.iconName)
                        Text(quest.difficulty.displayName)
                    }
                    .font(GQTheme.caption2Font)
                    .foregroundStyle(difficultyColor(quest.difficulty))

                    // Steps
                    Text("\(quest.steps.count) steps")
                        .font(GQTheme.caption2Font)
                        .foregroundStyle(.secondary)

                    // Rating
                    if quest.totalRatings > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text(String(format: "%.1f", quest.averageRating))
                        }
                        .font(GQTheme.caption2Font)
                    }
                }

                // Distance
                if let userLocation = appState.locationService.currentLocation {
                    let questLoc = CLLocation(latitude: quest.latitude, longitude: quest.longitude)
                    let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                    let distance = userLoc.distance(from: questLoc)
                    Text(formatDistance(distance))
                        .font(GQTheme.caption2Font)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Points
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(quest.pointValue)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(GQTheme.accent)
                Text("pts")
                    .font(GQTheme.caption2Font)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(GQTheme.paddingMedium)
        .background(GQTheme.cardBackground, in: RoundedRectangle(cornerRadius: GQTheme.cornerRadius))
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
