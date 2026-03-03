import FirebaseFirestore

final class LeaderboardService {
    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    func fetchGlobalLeaderboard(limit: Int = AppConstants.leaderboardTopCount) async throws -> [LeaderboardEntry] {
        try await firestoreService.queryOrdered(
            collection: AppConstants.Collections.leaderboardGlobal,
            orderBy: "totalScore",
            descending: true,
            limit: limit
        )
    }

    func fetchRegionalLeaderboard(city: String, limit: Int = AppConstants.leaderboardTopCount) async throws -> [LeaderboardEntry] {
        let allEntries: [LeaderboardEntry] = try await firestoreService.query(
            collection: AppConstants.Collections.leaderboardGlobal,
            field: "city",
            isEqualTo: city,
            orderBy: "totalScore",
            descending: true,
            limit: limit
        )
        return allEntries
    }

    func updateLeaderboardEntry(for user: GQUser) async throws {
        let entry = LeaderboardEntry(
            id: user.id,
            displayName: user.displayName,
            avatarConfig: user.avatarConfig,
            totalScore: user.totalScore,
            questsCompleted: user.questsCompleted,
            questsCreated: user.questsCreated,
            city: user.city
        )
        try await firestoreService.setDocument(
            collection: AppConstants.Collections.leaderboardGlobal,
            documentId: user.id,
            data: entry
        )
    }
}
