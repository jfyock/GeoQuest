import FirebaseAuth
import SwiftUI

@Observable
final class AppState {
    enum AuthPhase {
        case loading
        case unauthenticated
        case authenticated
    }

    var authPhase: AuthPhase = .loading
    var currentUser: GQUser?

    // Services
    let authService = AuthService()
    let locationService = LocationService()
    let firestoreService: FirestoreService
    let questService: QuestService
    let userService: UserService
    let leaderboardService: LeaderboardService
    let chatService = ChatService()
    let storageService = StorageService()

    init() {
        let firestore = FirestoreService()
        self.firestoreService = firestore
        self.questService = QuestService(firestoreService: firestore)
        self.userService = UserService(firestoreService: firestore)
        self.leaderboardService = LeaderboardService(firestoreService: firestore)
    }

    func initialize() async {
        authService.startListening()

        // Wait briefly for auth state to resolve
        try? await Task.sleep(for: .seconds(1.5))

        if let firebaseUser = authService.currentUser {
            await loadUserProfile(uid: firebaseUser.uid)
        }

        withAnimation(GQTheme.smooth) {
            authPhase = authService.isAuthenticated ? .authenticated : .unauthenticated
        }
    }

    func loadUserProfile(uid: String) async {
        do {
            if let user: GQUser = try await userService.fetchUser(id: uid) {
                currentUser = user
                // Update city from current location if available
                if currentUser?.city.isEmpty == true {
                    await locationService.reverseGeocodeCurrentLocation()
                    if !locationService.currentCity.isEmpty {
                        currentUser?.city = locationService.currentCity
                        try? await userService.updateCity(userId: uid, city: locationService.currentCity)
                    }
                }
            }
        } catch {
            print("[GeoQuest] Failed to load user profile: \(error)")
        }
    }

    func handleSignIn(uid: String) async {
        await loadUserProfile(uid: uid)
        withAnimation(GQTheme.smooth) {
            authPhase = .authenticated
        }
    }

    func handleSignUp(uid: String, email: String, displayName: String) async throws {
        let city = locationService.currentCity
        let newUser = GQUser(id: uid, email: email, displayName: displayName, city: city)
        try await userService.createUser(newUser)
        try await leaderboardService.updateLeaderboardEntry(for: newUser)
        currentUser = newUser
        withAnimation(GQTheme.smooth) {
            authPhase = .authenticated
        }
    }

    func handleSignOut() {
        try? authService.signOut()
        currentUser = nil
        chatService.stopListening()
        withAnimation(GQTheme.smooth) {
            authPhase = .unauthenticated
        }
    }
}
