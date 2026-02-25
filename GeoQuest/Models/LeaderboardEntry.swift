import Foundation

struct LeaderboardEntry: Codable, Identifiable, Sendable {
    var id: String
    var displayName: String
    var avatarConfig: AvatarConfig
    var totalScore: Int
    var questsCompleted: Int
    var questsCreated: Int
    var city: String
}
