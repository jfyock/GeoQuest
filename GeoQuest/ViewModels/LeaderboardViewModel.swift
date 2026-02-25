import SwiftUI

@Observable
final class LeaderboardViewModel {
    enum Tab: String, CaseIterable {
        case global = "Global"
        case regional = "Regional"
    }

    var selectedTab: Tab = .global
    var globalEntries: [LeaderboardEntry] = []
    var regionalEntries: [LeaderboardEntry] = []
    var isLoading = false
    var userCity: String = ""

    private let leaderboardService: LeaderboardService

    init(leaderboardService: LeaderboardService) {
        self.leaderboardService = leaderboardService
    }

    func load(city: String) async {
        userCity = city
        isLoading = true
        defer { isLoading = false }

        do {
            globalEntries = try await leaderboardService.fetchGlobalLeaderboard()
            if !city.isEmpty {
                regionalEntries = try await leaderboardService.fetchRegionalLeaderboard(city: city)
            }
        } catch {
            // Silent fail
        }
    }

    func refresh() async {
        await load(city: userCity)
    }

    var currentEntries: [LeaderboardEntry] {
        switch selectedTab {
        case .global: return globalEntries
        case .regional: return regionalEntries
        }
    }
}
