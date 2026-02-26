import SwiftUI

@Observable
final class FriendViewModel {
    private let friendService: FriendService
    private let userService: UserService

    var friends: [Friendship] = []
    var incomingRequests: [FriendRequest] = []
    var outgoingRequests: [FriendRequest] = []
    var searchResults: [GQUser] = []
    var searchQuery = ""
    var isLoading = false
    var isSearching = false
    var errorMessage: String?
    var successMessage: String?

    init(friendService: FriendService, userService: UserService) {
        self.friendService = friendService
        self.userService = userService
    }

    // MARK: - Load Data

    func loadAll(userId: String) async {
        isLoading = true
        defer { isLoading = false }

        async let friendsTask: () = loadFriends(userId: userId)
        async let incomingTask: () = loadIncomingRequests(userId: userId)
        async let outgoingTask: () = loadOutgoingRequests(userId: userId)

        _ = await (friendsTask, incomingTask, outgoingTask)
    }

    func loadFriends(userId: String) async {
        do {
            friends = try await friendService.fetchFriends(userId: userId)
        } catch {
            print("[GeoQuest] Failed to load friends: \(error)")
        }
    }

    func loadIncomingRequests(userId: String) async {
        do {
            let all = try await friendService.fetchIncomingRequests(userId: userId)
            incomingRequests = all.filter { $0.status == .pending }
        } catch {
            print("[GeoQuest] Failed to load incoming requests: \(error)")
        }
    }

    func loadOutgoingRequests(userId: String) async {
        do {
            outgoingRequests = try await friendService.fetchOutgoingRequests(userId: userId)
        } catch {
            print("[GeoQuest] Failed to load outgoing requests: \(error)")
        }
    }

    // MARK: - Search

    func searchUsers(currentUserId: String) async {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            searchResults = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            let results = try await friendService.searchUsers(query: trimmed)
            // Filter out self and existing friends
            let friendIds = Set(friends.map(\.friendId))
            searchResults = results.filter { user in
                user.id != currentUserId && !friendIds.contains(user.id)
            }
        } catch {
            print("[GeoQuest] Search failed: \(error)")
            searchResults = []
        }
    }

    // MARK: - Friend Requests

    func sendRequest(from currentUser: GQUser, to targetUser: GQUser) async {
        let request = FriendRequest(
            fromUserId: currentUser.id,
            fromDisplayName: currentUser.displayName,
            fromAvatarConfig: currentUser.avatarConfig,
            toUserId: targetUser.id,
            toDisplayName: targetUser.displayName
        )

        do {
            try await friendService.sendFriendRequest(request)
            outgoingRequests.insert(request, at: 0)
            withAnimation(GQTheme.bouncy) {
                successMessage = "Request sent to \(targetUser.displayName)!"
            }
        } catch {
            errorMessage = "Failed to send request"
        }
    }

    func acceptRequest(_ request: FriendRequest) async {
        do {
            try await friendService.acceptFriendRequest(request)
            withAnimation(GQTheme.bouncy) {
                incomingRequests.removeAll { $0.id == request.id }
                let friendship = Friendship(
                    userId: request.toUserId,
                    friendId: request.fromUserId,
                    friendDisplayName: request.fromDisplayName,
                    friendAvatarConfig: request.fromAvatarConfig
                )
                friends.insert(friendship, at: 0)
                successMessage = "\(request.fromDisplayName) is now your friend!"
            }
        } catch {
            errorMessage = "Failed to accept request"
        }
    }

    func rejectRequest(_ request: FriendRequest) async {
        do {
            try await friendService.rejectFriendRequest(request)
            withAnimation(GQTheme.bouncy) {
                incomingRequests.removeAll { $0.id == request.id }
            }
        } catch {
            errorMessage = "Failed to reject request"
        }
    }

    func hasPendingRequest(toUserId: String) -> Bool {
        outgoingRequests.contains { $0.toUserId == toUserId && $0.status == .pending }
    }

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
