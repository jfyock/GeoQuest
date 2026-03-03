import Foundation

struct GQUser: Codable, Identifiable, Sendable {
    var id: String
    var email: String
    var displayName: String
    var avatarConfig: AvatarConfig
    var totalScore: Int
    var questsCreated: Int
    var questsCompleted: Int
    var city: String
    var joinedAt: Date
    var lastActiveAt: Date

    init(
        id: String,
        email: String,
        displayName: String,
        city: String = ""
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarConfig = .default
        self.totalScore = 0
        self.questsCreated = 0
        self.questsCompleted = 0
        self.city = city
        self.joinedAt = Date()
        self.lastActiveAt = Date()
    }
}
