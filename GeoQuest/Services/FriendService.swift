import FirebaseFirestore

final class FriendService {
    private let firestoreService: FirestoreService

    init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }

    // MARK: - Search Users

    func searchUsers(query: String) async throws -> [GQUser] {
        let lowercased = query.lowercased()
        return try await firestoreService.queryWithPrefix(
            collection: AppConstants.Collections.users,
            field: "displayName",
            prefix: lowercased
        )
    }

    // MARK: - Friend Requests

    func sendFriendRequest(_ request: FriendRequest) async throws {
        try await firestoreService.setDocument(
            collection: AppConstants.Collections.friendRequests,
            documentId: request.id,
            data: request
        )
    }

    func fetchIncomingRequests(userId: String) async throws -> [FriendRequest] {
        try await firestoreService.query(
            collection: AppConstants.Collections.friendRequests,
            field: "toUserId",
            isEqualTo: userId,
            orderBy: "createdAt",
            descending: true
        )
    }

    func fetchOutgoingRequests(userId: String) async throws -> [FriendRequest] {
        try await firestoreService.query(
            collection: AppConstants.Collections.friendRequests,
            field: "fromUserId",
            isEqualTo: userId,
            orderBy: "createdAt",
            descending: true
        )
    }

    func acceptFriendRequest(_ request: FriendRequest) async throws {
        // Update request status
        try await firestoreService.updateFields(
            collection: AppConstants.Collections.friendRequests,
            documentId: request.id,
            fields: ["status": FriendRequestStatus.accepted.rawValue]
        )

        // Create friendship for both users
        let friendship1 = Friendship(
            userId: request.toUserId,
            friendId: request.fromUserId,
            friendDisplayName: request.fromDisplayName,
            friendAvatarConfig: request.fromAvatarConfig
        )
        let friendship2 = Friendship(
            userId: request.fromUserId,
            friendId: request.toUserId,
            friendDisplayName: request.toDisplayName,
            friendAvatarConfig: request.fromAvatarConfig
        )

        try await firestoreService.setDocument(
            collection: AppConstants.Collections.friendships,
            documentId: friendship1.id,
            data: friendship1
        )
        try await firestoreService.setDocument(
            collection: AppConstants.Collections.friendships,
            documentId: friendship2.id,
            data: friendship2
        )
    }

    func rejectFriendRequest(_ request: FriendRequest) async throws {
        try await firestoreService.updateFields(
            collection: AppConstants.Collections.friendRequests,
            documentId: request.id,
            fields: ["status": FriendRequestStatus.rejected.rawValue]
        )
    }

    // MARK: - Friends List

    func fetchFriends(userId: String) async throws -> [Friendship] {
        try await firestoreService.query(
            collection: AppConstants.Collections.friendships,
            field: "userId",
            isEqualTo: userId,
            orderBy: "createdAt",
            descending: true
        )
    }

    func removeFriend(friendshipId: String) async throws {
        try await firestoreService.deleteDocument(
            collection: AppConstants.Collections.friendships,
            documentId: friendshipId
        )
    }
}
