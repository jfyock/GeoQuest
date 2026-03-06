import FirebaseFirestore

final class QuestService {
    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    func createQuest(_ quest: Quest) async throws -> String {
        try await firestoreService.addDocument(
            collection: AppConstants.Collections.quests,
            data: quest
        )
    }

    func fetchQuest(id: String) async throws -> Quest? {
        try await firestoreService.getDocument(
            collection: AppConstants.Collections.quests,
            documentId: id
        )
    }

    func fetchQuestsByGeoHash(prefix: String) async throws -> [Quest] {
        try await firestoreService.queryWithPrefix(
            collection: AppConstants.Collections.quests,
            field: "geoHash",
            prefix: prefix
        )
    }

    func fetchQuestsInRegion(centerLat: Double, centerLon: Double) async throws -> [Quest] {
        let hashes = GeoHash.neighborHashes(latitude: centerLat, longitude: centerLon)
        var allQuests: [Quest] = []
        for hash in hashes {
            let quests: [Quest] = try await fetchQuestsByGeoHash(prefix: hash)
            allQuests.append(contentsOf: quests.filter { $0.isActive })
        }
        // Deduplicate by id
        var seen = Set<String>()
        return allQuests.filter { seen.insert($0.id).inserted }
    }

    func fetchQuestsByCreator(userId: String) async throws -> [Quest] {
        try await firestoreService.query(
            collection: AppConstants.Collections.quests,
            field: "creatorId",
            isEqualTo: userId,
            orderBy: "createdAt",
            descending: true
        )
    }

    func completeQuest(questId: String, completion: QuestCompletion) async throws {
        // Write completion record
        try await firestoreService.setSubDocument(
            parentCollection: AppConstants.Collections.quests,
            parentId: questId,
            subCollection: AppConstants.Collections.completions,
            documentId: completion.userId,
            data: completion
        )
        // Increment completion count on quest
        try await firestoreService.updateFields(
            collection: AppConstants.Collections.quests,
            documentId: questId,
            fields: ["totalCompletions": FieldValue.increment(Int64(1))]
        )
    }

    func rateQuest(questId: String, rating: QuestRating) async throws {
        // Write rating record
        try await firestoreService.setSubDocument(
            parentCollection: AppConstants.Collections.quests,
            parentId: questId,
            subCollection: AppConstants.Collections.ratings,
            documentId: rating.userId,
            data: rating
        )

        // Fetch all ratings to recalculate average
        let ratings: [QuestRating] = try await firestoreService.querySubCollection(
            parentCollection: AppConstants.Collections.quests,
            parentId: questId,
            subCollection: AppConstants.Collections.ratings
        )

        let totalRatings = ratings.count
        let averageRating = totalRatings > 0
            ? Double(ratings.reduce(0) { $0 + $1.rating }) / Double(totalRatings)
            : 0.0

        try await firestoreService.updateFields(
            collection: AppConstants.Collections.quests,
            documentId: questId,
            fields: [
                "averageRating": averageRating,
                "totalRatings": totalRatings
            ]
        )
    }

    func hasUserCompleted(questId: String, userId: String) async throws -> Bool {
        let completion: QuestCompletion? = try await firestoreService.getSubDocument(
            parentCollection: AppConstants.Collections.quests,
            parentId: questId,
            subCollection: AppConstants.Collections.completions,
            documentId: userId
        )
        return completion != nil
    }

    func fetchCompletions(questId: String) async throws -> [QuestCompletion] {
        try await firestoreService.querySubCollection(
            parentCollection: AppConstants.Collections.quests,
            parentId: questId,
            subCollection: AppConstants.Collections.completions,
            orderBy: "completedAt",
            descending: true
        )
    }

    func fetchRatings(questId: String) async throws -> [QuestRating] {
        try await firestoreService.querySubCollection(
            parentCollection: AppConstants.Collections.quests,
            parentId: questId,
            subCollection: AppConstants.Collections.ratings,
            orderBy: "createdAt",
            descending: true
        )
    }

    func updateImageURL(questId: String, imageURL: String) async throws {
        try await firestoreService.updateFields(
            collection: AppConstants.Collections.quests,
            documentId: questId,
            fields: ["imageURL": imageURL]
        )
    }

    func deactivateQuest(questId: String) async throws {
        try await firestoreService.updateFields(
            collection: AppConstants.Collections.quests,
            documentId: questId,
            fields: ["isActive": false]
        )
    }

    /// Deactivates every auto-generated quest in the 9-geohash region.
    /// Used before force-regenerating to replace stale quests with fresh content.
    func deactivateAutoGeneratedQuestsInRegion(centerLat: Double, centerLon: Double) async throws {
        let hashes = GeoHash.neighborHashes(latitude: centerLat, longitude: centerLon)
        for hash in hashes {
            let quests: [Quest] = try await fetchQuestsByGeoHash(prefix: hash)
            for quest in quests where quest.creatorId.hasPrefix(AppConstants.Generation.creatorIdPrefix) && !quest.id.isEmpty {
                try? await deactivateQuest(questId: quest.id)
            }
        }
    }

    func searchQuests(text: String) async throws -> [Quest] {
        // Simple search by title prefix (Firestore doesn't support full-text search)
        let allQuests: [Quest] = try await firestoreService.queryOrdered(
            collection: AppConstants.Collections.quests,
            orderBy: "createdAt",
            descending: true,
            limit: 100
        )
        let lowercased = text.lowercased()
        return allQuests.filter {
            $0.isActive && ($0.title.lowercased().contains(lowercased)
                || $0.description.lowercased().contains(lowercased))
        }
    }
}
