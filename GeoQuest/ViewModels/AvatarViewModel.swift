import SwiftUI

@Observable
final class AvatarViewModel {
    var config: AvatarConfig
    var isSaving = false
    var showSavedToast = false

    private let userService: UserService
    private let leaderboardService: LeaderboardService

    init(config: AvatarConfig, userService: UserService, leaderboardService: LeaderboardService) {
        self.config = config
        self.userService = userService
        self.leaderboardService = leaderboardService
    }

    func save(userId: String, appState: AppState) async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await userService.updateAvatar(userId: userId, config: config)
            appState.currentUser?.avatarConfig = config

            // Update leaderboard entry with new avatar
            if let user = appState.currentUser {
                try await leaderboardService.updateLeaderboardEntry(for: user)
            }

            withAnimation(GQTheme.bouncy) {
                showSavedToast = true
            }
        } catch {
            // Save failed - non-critical, avatar persists locally
        }
    }
}
