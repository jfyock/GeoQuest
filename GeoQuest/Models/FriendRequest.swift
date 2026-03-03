import Foundation

struct FriendRequest: Codable, Identifiable, Sendable {
    var id: String
    var fromUserId: String
    var fromDisplayName: String
    var fromAvatarConfig: AvatarConfig
    var toUserId: String
    var toDisplayName: String
    var status: FriendRequestStatus
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        fromUserId: String,
        fromDisplayName: String,
        fromAvatarConfig: AvatarConfig,
        toUserId: String,
        toDisplayName: String,
        status: FriendRequestStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.fromUserId = fromUserId
        self.fromDisplayName = fromDisplayName
        self.fromAvatarConfig = fromAvatarConfig
        self.toUserId = toUserId
        self.toDisplayName = toDisplayName
        self.status = status
        self.createdAt = createdAt
    }
}

enum FriendRequestStatus: String, Codable, Sendable {
    case pending
    case accepted
    case rejected
}

struct Friendship: Codable, Identifiable, Sendable {
    var id: String
    var userId: String
    var friendId: String
    var friendDisplayName: String
    var friendAvatarConfig: AvatarConfig
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        friendId: String,
        friendDisplayName: String,
        friendAvatarConfig: AvatarConfig,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.friendId = friendId
        self.friendDisplayName = friendDisplayName
        self.friendAvatarConfig = friendAvatarConfig
        self.createdAt = createdAt
    }
}
