import SwiftUI

@Observable
final class QuestDetailViewModel {
    enum ViewState {
        case loading
        case loaded
        case error(String)
    }

    enum PlayState {
        case notStarted
        case playing(currentStep: Int)
        case enteringCode
        case completed
    }

    var state: ViewState = .loading
    var playState: PlayState = .notStarted
    var quest: Quest?
    var isCompletedByUser = false
    var enteredCode = ""
    var codeError: String?
    var startTime: Date?
    var showRating = false
    var ratingValue = 0
    var feedbackText = ""
    var pointsEarned = 0

    private let questService: QuestService
    private let userService: UserService
    private let leaderboardService: LeaderboardService

    init(questService: QuestService, userService: UserService, leaderboardService: LeaderboardService) {
        self.questService = questService
        self.userService = userService
        self.leaderboardService = leaderboardService
    }

    func loadQuest(id: String, userId: String) async {
        state = .loading
        do {
            quest = try await questService.fetchQuest(id: id)
            isCompletedByUser = try await questService.hasUserCompleted(questId: id, userId: userId)
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func startQuest() {
        startTime = Date()
        withAnimation(GQTheme.bouncy) {
            playState = .playing(currentStep: 0)
        }
    }

    func nextStep() {
        guard let quest else { return }
        if case .playing(let current) = playState {
            if current + 1 < quest.steps.count {
                withAnimation(GQTheme.bouncy) {
                    playState = .playing(currentStep: current + 1)
                }
            } else {
                withAnimation(GQTheme.bouncy) {
                    playState = .enteringCode
                }
            }
        }
    }

    func previousStep() {
        if case .playing(let current) = playState, current > 0 {
            withAnimation(GQTheme.bouncy) {
                playState = .playing(currentStep: current - 1)
            }
        }
    }

    func submitCode(userId: String, userDisplayName: String) async -> Bool {
        guard let quest else { return false }

        if enteredCode.uppercased() != quest.secretCode.uppercased() {
            codeError = "Wrong code! Keep searching."
            return false
        }

        codeError = nil

        let elapsed = startTime.map { Int(Date().timeIntervalSince($0)) }
        let completion = QuestCompletion(
            userId: userId,
            userDisplayName: userDisplayName,
            timeToCompleteSeconds: elapsed
        )

        do {
            try await questService.completeQuest(questId: quest.id, completion: completion)
            pointsEarned = ScoreCalculator.completionPoints(quest: quest)
            try await userService.updateScore(userId: userId, additionalPoints: pointsEarned)
            try await userService.incrementQuestsCompleted(userId: userId)

            // Award creator bonus
            try await userService.updateScore(
                userId: quest.creatorId,
                additionalPoints: ScoreCalculator.creatorCompletionBonus
            )

            isCompletedByUser = true
            withAnimation(GQTheme.bouncy) {
                playState = .completed
                showRating = true
            }
            return true
        } catch {
            codeError = "Failed to record completion. Try again."
            return false
        }
    }

    func submitRating(userId: String, userDisplayName: String) async {
        guard let quest, ratingValue > 0 else { return }

        let rating = QuestRating(
            userId: userId,
            userDisplayName: userDisplayName,
            rating: ratingValue,
            feedback: feedbackText
        )

        do {
            try await questService.rateQuest(questId: quest.id, rating: rating)
            showRating = false
        } catch {
            // Rating failed - non-critical
        }
    }
}
