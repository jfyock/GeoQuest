import FirebaseFirestore

final class UserService {
    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    func createUser(_ user: GQUser) async throws {
        try await firestoreService.setDocument(
            collection: AppConstants.Collections.users,
            documentId: user.id,
            data: user
        )
    }

    func fetchUser(id: String) async throws -> GQUser? {
        try await firestoreService.getDocument(
            collection: AppConstants.Collections.users,
            documentId: id
        )
    }

    func updateUser(_ user: GQUser) async throws {
        try await firestoreService.setDocument(
            collection: AppConstants.Collections.users,
            documentId: user.id,
            data: user
        )
    }

    func updateAvatar(userId: String, config: AvatarConfig) async throws {
        let data = try JSONEncoder().encode(config)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        try await firestoreService.updateFields(
            collection: AppConstants.Collections.users,
            documentId: userId,
            fields: ["avatarConfig": dict]
        )
    }

    func updateScore(userId: String, additionalPoints: Int) async throws {
        try await firestoreService.updateFields(
            collection: AppConstants.Collections.users,
            documentId: userId,
            fields: [
                "totalScore": FieldValue.increment(Int64(additionalPoints)),
                "lastActiveAt": Date()
            ]
        )
    }

    func incrementQuestsCreated(userId: String) async throws {
        try await firestoreService.updateFields(
            collection: AppConstants.Collections.users,
            documentId: userId,
            fields: ["questsCreated": FieldValue.increment(Int64(1))]
        )
    }

    func incrementQuestsCompleted(userId: String) async throws {
        try await firestoreService.updateFields(
            collection: AppConstants.Collections.users,
            documentId: userId,
            fields: ["questsCompleted": FieldValue.increment(Int64(1))]
        )
    }

    func updateCity(userId: String, city: String) async throws {
        try await firestoreService.updateFields(
            collection: AppConstants.Collections.users,
            documentId: userId,
            fields: ["city": city]
        )
    }
}

extension UserService {
    func addGems(userId: String, gems: Int) async throws {
        try await firestoreService.updateFields(
            collection: AppConstants.Collections.users,
            documentId: userId,
            fields: ["gems": FieldValue.increment(Int64(gems))]
        )
    }

    /// Updates streak state after computing the new streak server-side.
    func updateStreak(userId: String, currentStreak: Int, longestStreak: Int, lastLoginDate: Date) async throws {
        try await firestoreService.updateFields(
            collection: AppConstants.Collections.users,
            documentId: userId,
            fields: [
                "currentStreak": currentStreak,
                "longestStreak": longestStreak,
                "lastLoginDate": lastLoginDate,
                "lastActiveAt": Date(),
            ]
        )
    }
}
