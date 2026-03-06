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
    nonisolated(unsafe) static let leaderboardTopCount = 10

    // Map
    static let defaultMapSpanDelta = 0.05
    static let geoHashPrecision = 5

    // Avatar
    static let avatarDefaultSize: CGFloat = 60
    static let avatarMapSize: CGFloat = 44
    static let playerAnnotationMinScale: CGFloat = 0.6
    static let playerAnnotationMaxScale: CGFloat = 1.5

    // Quest proximity
    static let questProximityRadius: Double = 50

    // Cosmetics
    static let cosmeticDropChance: Double = 0.15

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

    // Daily objectives
    enum Daily {
        /// Subcollection name under each user document.
        static let subcollection = "daily"
        /// Gems awarded just for logging in each day.
        static let loginGems = 10
        /// Streak milestone intervals that award bonus gems (e.g. every 7 days).
        static let streakMilestoneInterval = 7
        /// Bonus gems at each milestone.
        static let streakMilestoneGems = 50
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
        static let cosmetics = "cosmetics"
    }
}
