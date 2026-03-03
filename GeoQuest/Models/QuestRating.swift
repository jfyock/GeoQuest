import Foundation

struct QuestRating: Codable, Identifiable, Sendable {
    var id: String
    var userId: String
    var userDisplayName: String
    var rating: Int
    var feedback: String
    var createdAt: Date

    init(userId: String, userDisplayName: String, rating: Int, feedback: String = "") {
        self.id = userId
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.rating = min(max(rating, 1), 5)
        self.feedback = feedback
        self.createdAt = Date()
    }
}
