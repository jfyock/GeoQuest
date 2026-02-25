import Foundation

struct QuestCompletion: Codable, Identifiable, Sendable {
    var id: String
    var userId: String
    var userDisplayName: String
    var completedAt: Date
    var timeToCompleteSeconds: Int?

    init(userId: String, userDisplayName: String, timeToCompleteSeconds: Int? = nil) {
        self.id = userId
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.completedAt = Date()
        self.timeToCompleteSeconds = timeToCompleteSeconds
    }
}
