import SwiftUI

struct LeaderboardView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: LeaderboardViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    leaderboardContent(viewModel: viewModel)
                } else {
                    GQLoadingIndicator()
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = LeaderboardViewModel(leaderboardService: appState.leaderboardService)
            }
            Task {
                await viewModel?.load(city: appState.currentUser?.city ?? "")
            }
        }
    }

    private func leaderboardContent(viewModel: LeaderboardViewModel) -> some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("Leaderboard", selection: Binding(
                get: { viewModel.selectedTab },
                set: { viewModel.selectedTab = $0 }
            )) {
                ForEach(LeaderboardViewModel.Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, GQTheme.paddingLarge)
            .padding(.vertical, GQTheme.paddingMedium)

            // Regional subtitle
            if viewModel.selectedTab == .regional {
                if viewModel.userCity.isEmpty {
                    Text("Enable location to see regional rankings")
                        .font(GQTheme.captionFont)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(GQTheme.primary)
                        Text(viewModel.userCity)
                            .fontWeight(.semibold)
                    }
                    .font(GQTheme.captionFont)
                    .padding(.bottom, 8)
                }
            }

            if viewModel.isLoading {
                Spacer()
                GQLoadingIndicator(message: "Loading rankings...")
                Spacer()
            } else if viewModel.currentEntries.isEmpty {
                Spacer()
                VStack(spacing: 14) {
                    Image(systemName: "trophy")
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(GQTheme.gold.opacity(0.4))
                        .symbolEffect(.bounce, options: .repeating.speed(0.3))
                    Text("No rankings yet")
                        .font(GQTheme.title3Font)
                        .foregroundStyle(.secondary)
                    Text("Complete quests to climb the leaderboard!")
                        .font(GQTheme.captionFont)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(viewModel.currentEntries.enumerated()), id: \.element.id) { index, entry in
                            LeaderboardRowView(rank: index + 1, entry: entry)
                        }
                    }
                    .padding(.horizontal, GQTheme.paddingMedium)
                    .padding(.bottom, GQTheme.paddingLarge)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
    }
}
