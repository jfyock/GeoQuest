import Foundation

enum QuestDifficulty: String, Codable, CaseIterable, Sendable {
    case easy
    case medium
    case hard
    case expert

    var displayName: String {
        rawValue.capitalized
    }

    var iconName: String {
        switch self {
        case .easy: return "leaf.fill"
        case .medium: return "flame.fill"
        case .hard: return "bolt.fill"
        case .expert: return "star.fill"
        }
    }
}

struct Quest: Codable, Identifiable, Sendable {
    var id: String
    var creatorId: String
    var creatorDisplayName: String
    var title: String
    var description: String
    var latitude: Double
    var longitude: Double
    var geoHash: String
    var steps: [QuestStep]
    var secretCode: String
    var iconName: String
    var iconColor: String
    var difficulty: QuestDifficulty
    var totalCompletions: Int
    var averageRating: Double
    var totalRatings: Int
    var pointValue: Int
    var isActive: Bool
    var createdAt: Date

    init(
        id: String = "",
        creatorId: String,
        creatorDisplayName: String,
        title: String,
        description: String,
        latitude: Double,
        longitude: Double,
        steps: [QuestStep],
        secretCode: String,
        iconName: String = "mappin.circle.fill",
        iconColor: String = "FF6B35",
        difficulty: QuestDifficulty = .medium,
        isActive: Bool = true
    ) {
        self.id = id
        self.creatorId = creatorId
        self.creatorDisplayName = creatorDisplayName
        self.title = title
        self.description = description
        self.latitude = latitude
        self.longitude = longitude
        self.geoHash = GeoHash.encode(latitude: latitude, longitude: longitude)
        self.steps = steps
        self.secretCode = secretCode.uppercased()
        self.iconName = iconName
        self.iconColor = iconColor
        self.difficulty = difficulty
        self.totalCompletions = 0
        self.averageRating = 0
        self.totalRatings = 0
        self.pointValue = ScoreCalculator.baseQuestValue(stepCount: steps.count)
        self.isActive = isActive
        self.createdAt = Date()
    }
}
