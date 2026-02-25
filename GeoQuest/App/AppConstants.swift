import Foundation

enum AppConstants {
    static let appName = "GeoQuest"
    static let appVersion = "1.0.0"

    // Quest constraints
    static let maxQuestSteps = 10
    static let minQuestSteps = 1
    static let maxStepCharacters = 255
    static let maxQuestTitleCharacters = 100
    static let maxQuestDescriptionCharacters = 500
    static let minSecretCodeLength = 4
    static let maxSecretCodeLength = 20

    // Chat constraints
    static let maxChatMessageLength = 500
    static let chatMessageFetchLimit = 100

    // Leaderboard
    static let leaderboardTopCount = 10

    // Map
    static let defaultMapSpanDelta = 0.05
    static let geoHashPrecision = 5

    // Avatar
    static let avatarDefaultSize: CGFloat = 60
    static let avatarMapSize: CGFloat = 44

    // Loading screen
    static let loadingScreenRotationInterval: TimeInterval = 3.0

    // Firestore collections
    enum Collections {
        static let users = "users"
        static let quests = "quests"
        static let completions = "completions"
        static let ratings = "ratings"
        static let chatMessages = "chat_messages"
        static let leaderboardGlobal = "leaderboard_global"
    }
}
