import SwiftUI

@Observable
final class DailyViewModel {
    var objectives: [DailyObjective] = []
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var loginBonusClaimed: Bool = false
    var isLoading = false
    var claimAnimation: Int? = nil   // index being animated after claim
    var errorMessage: String? = nil

    var allObjectivesComplete: Bool {
        objectives.allSatisfy { $0.isComplete && $0.isClaimed }
    }

    /// Gems the player earns just for today's login (before streak milestone check).
    var loginBonusGems: Int {
        var gems = AppConstants.Daily.loginGems
        if currentStreak > 0 && currentStreak % AppConstants.Daily.streakMilestoneInterval == 0 {
            gems += AppConstants.Daily.streakMilestoneGems
        }
        return gems
    }

    var nextMilestone: Int {
        let interval = AppConstants.Daily.streakMilestoneInterval
        return ((currentStreak / interval) + 1) * interval
    }

    private let dailyService: DailyObjectiveService
    private let userId: String

    init(dailyService: DailyObjectiveService, userId: String, currentStreak: Int, longestStreak: Int) {
        self.dailyService = dailyService
        self.userId = userId
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            objectives = try await dailyService.loadTodayObjectives(userId: userId)
            loginBonusClaimed = try await dailyService.isTodayLoginBonusClaimed(userId: userId)
        } catch {
            errorMessage = "Couldn't load daily challenges."
        }
    }

    func claimObjective(at index: Int) async {
        do {
            let updated = try await dailyService.claimObjective(index: index, userId: userId)
            withAnimation(GQTheme.bouncy) {
                objectives = updated
                claimAnimation = index
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.claimAnimation = nil
            }
        } catch {
            errorMessage = "Couldn't claim reward. Try again."
        }
    }

    func claimLoginBonus() async {
        do {
            try await dailyService.claimLoginBonus(userId: userId, streak: currentStreak)
            withAnimation(GQTheme.bouncy) { loginBonusClaimed = true }
        } catch {
            errorMessage = "Couldn't claim login bonus."
        }
    }
}
