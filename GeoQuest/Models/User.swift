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
    var gems: Int
    var ownedCosmeticIds: [String]

    enum CodingKeys: String, CodingKey {
        case id, email, displayName, avatarConfig, totalScore
        case questsCreated, questsCompleted, city, joinedAt, lastActiveAt
        case gems, ownedCosmeticIds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        displayName = try container.decode(String.self, forKey: .displayName)
        avatarConfig = try container.decode(AvatarConfig.self, forKey: .avatarConfig)
        totalScore = try container.decode(Int.self, forKey: .totalScore)
        questsCreated = try container.decode(Int.self, forKey: .questsCreated)
        questsCompleted = try container.decode(Int.self, forKey: .questsCompleted)
        city = try container.decode(String.self, forKey: .city)
        joinedAt = try container.decode(Date.self, forKey: .joinedAt)
        lastActiveAt = try container.decode(Date.self, forKey: .lastActiveAt)
        gems = try container.decodeIfPresent(Int.self, forKey: .gems) ?? 0
        ownedCosmeticIds = try container.decodeIfPresent([String].self, forKey: .ownedCosmeticIds) ?? []
    }

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
        self.gems = 0
        self.ownedCosmeticIds = []
    }
}
