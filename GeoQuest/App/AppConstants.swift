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

    // Friends
    static let maxFriendSearchResults = 20

    // Quest generation
    enum Generation {
        /// Max quests (generated + user-created) in a 9-geohash region before
        /// generation stops. Prevents overloading any single area.
        static let maxQuestsPerRegion = 15
        /// How many quests to create in one generation pass.
        static let batchSizeRange = 3...5
        /// Radius (meters) to search for nearby points of interest.
        static let poiSearchRadiusMeters: Double = 800
        /// Creator ID prefix so generated quests can be identified programmatically.
        static let creatorIdPrefix = "geoquest_generated_"
    }

    // Firestore collections
    enum Collections {
        static let users = "users"
        static let quests = "quests"
        static let completions = "completions"
        static let ratings = "ratings"
        static let chatMessages = "chat_messages"
        static let leaderboardGlobal = "leaderboard_global"
        static let friendRequests = "friend_requests"
        static let friendships = "friendships"
    }
}
