import Foundation

/// Manages daily login streaks and daily objective progress.
/// State is persisted in Firestore at `users/{userId}/daily/{dateKey}`.
final class DailyObjectiveService {
    private let firestoreService: FirestoreService
    private let userService: UserService

    init(firestoreService: FirestoreService, userService: UserService) {
        self.firestoreService = firestoreService
        self.userService = userService
    }

    // MARK: - Public API

    /// Called on app launch after the user profile is loaded.
    /// - Computes and saves the updated streak.
    /// - Ensures today's daily document exists in Firestore.
    /// - Returns the updated user so callers can refresh local state.
    func handleDailyLogin(user: GQUser) async throws -> GQUser {
        var updated = user
        let today = Date()
        let calendar = Calendar.current

        // --- Streak logic ---
        if let last = user.lastLoginDate {
            if calendar.isDateInToday(last) {
                // Already counted today — no change
            } else if calendar.isYesterday(last) {
                // Consecutive day → extend streak
                updated.currentStreak += 1
                updated.longestStreak = max(updated.longestStreak, updated.currentStreak)
                updated.lastLoginDate = today
                try await userService.updateStreak(
                    userId: updated.id,
                    currentStreak: updated.currentStreak,
                    longestStreak: updated.longestStreak,
                    lastLoginDate: today
                )
            } else {
                // Missed at least one day → reset
                updated.currentStreak = 1
                updated.lastLoginDate = today
                try await userService.updateStreak(
                    userId: updated.id,
                    currentStreak: 1,
                    longestStreak: updated.longestStreak,
                    lastLoginDate: today
                )
            }
        } else {
            // First ever login — start streak
            updated.currentStreak = 1
            updated.longestStreak = 1
            updated.lastLoginDate = today
            try await userService.updateStreak(
                userId: updated.id,
                currentStreak: 1,
                longestStreak: 1,
                lastLoginDate: today
            )
        }

        // --- Ensure today's daily document exists ---
        _ = try await loadOrCreateTodayState(userId: user.id)

        return updated
    }

    /// Loads today's objective state merged with the deterministic templates.
    func loadTodayObjectives(userId: String) async throws -> [DailyObjective] {
        let state = try await loadOrCreateTodayState(userId: userId)
        let templates = DailyObjectivePool.todaysObjectives()
        return templates.map { template in
            DailyObjective(
                template: template,
                progress: state.progress[safe: template.index] ?? 0,
                isClaimed: state.claimed[safe: template.index] ?? false
            )
        }
    }

    /// Increments progress for all objectives whose type matches `type`.
    /// Should be called whenever a qualifying player action occurs.
    @discardableResult
    func recordEvent(type: DailyObjectiveType, userId: String, amount: Int = 1) async throws -> [DailyObjective] {
        var state = try await loadOrCreateTodayState(userId: userId)
        let templates = DailyObjectivePool.todaysObjectives()

        for template in templates where template.type == type {
            let idx = template.index
            guard idx < state.progress.count else { continue }
            state.progress[idx] = min(state.progress[idx] + amount, template.targetCount)
        }

        try await saveTodayState(userId: userId, state: state)

        return templates.map { template in
            DailyObjective(
                template: template,
                progress: state.progress[safe: template.index] ?? 0,
                isClaimed: state.claimed[safe: template.index] ?? false
            )
        }
    }

    /// Claims the reward for a completed objective. Awards points + gems.
    /// Returns the updated objectives list.
    @discardableResult
    func claimObjective(index: Int, userId: String) async throws -> [DailyObjective] {
        var state = try await loadOrCreateTodayState(userId: userId)
        let templates = DailyObjectivePool.todaysObjectives()

        guard
            index < templates.count,
            index < state.progress.count,
            !state.claimed[safe: index, default: true]
        else { return [] }

        let template = templates[index]
        guard state.progress[index] >= template.targetCount else { return [] }

        state.claimed[index] = true
        try await saveTodayState(userId: userId, state: state)

        // Award rewards
        try await userService.updateScore(userId: userId, additionalPoints: template.rewardPoints)
        try await userService.addGems(userId: userId, gems: template.rewardGems)

        return templates.map { t in
            DailyObjective(
                template: t,
                progress: state.progress[safe: t.index] ?? 0,
                isClaimed: state.claimed[safe: t.index] ?? false
            )
        }
    }

    /// Claims the daily login bonus gems. Safe to call multiple times — only awards once per day.
    func claimLoginBonus(userId: String, streak: Int) async throws {
        var state = try await loadOrCreateTodayState(userId: userId)
        guard !state.loginBonusClaimed else { return }
        state.loginBonusClaimed = true
        try await saveTodayState(userId: userId, state: state)

        var gemsToAward = AppConstants.Daily.loginGems
        // Streak milestone bonus
        if streak > 0 && streak % AppConstants.Daily.streakMilestoneInterval == 0 {
            gemsToAward += AppConstants.Daily.streakMilestoneGems
        }
        try await userService.addGems(userId: userId, gems: gemsToAward)
    }

    func isTodayLoginBonusClaimed(userId: String) async throws -> Bool {
        let state = try await loadOrCreateTodayState(userId: userId)
        return state.loginBonusClaimed
    }

    // MARK: - Private persistence

    private func loadOrCreateTodayState(userId: String) async throws -> DailyStateDocument {
        let dateKey = Calendar.current.dateKey(for: Date())
        let existing: DailyStateDocument? = try await firestoreService.getSubDocument(
            parentCollection: AppConstants.Collections.users,
            parentId: userId,
            subCollection: AppConstants.Daily.subcollection,
            documentId: dateKey
        )
        if let doc = existing, doc.dateKey == dateKey {
            // Ensure arrays are long enough (guard against stale documents)
            var safe = doc
            while safe.progress.count < 3 { safe.progress.append(0) }
            while safe.claimed.count < 3 { safe.claimed.append(false) }
            return safe
        }
        let fresh = DailyStateDocument.fresh(dateKey: dateKey)
        try await saveTodayState(userId: userId, state: fresh)
        return fresh
    }

    private func saveTodayState(userId: String, state: DailyStateDocument) async throws {
        let dateKey = Calendar.current.dateKey(for: Date())
        try await firestoreService.setSubDocument(
            parentCollection: AppConstants.Collections.users,
            parentId: userId,
            subCollection: AppConstants.Daily.subcollection,
            documentId: dateKey,
            data: state
        )
    }
}

// MARK: - Safe array subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
    subscript(safe index: Int, default defaultValue: Element) -> Element {
        indices.contains(index) ? self[index] : defaultValue
    }
}
