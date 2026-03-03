import FirebaseAuth
import SwiftUI
import AuthenticationServices

@Observable
final class AuthViewModel {
    enum AuthMode {
        case login
        case signUp
        case usernameSetup
    }

    enum AuthState {
        case idle
        case loading
        case error(String)
    }

    var mode: AuthMode = .login
    var state: AuthState = .idle

    // Login fields
    var email = ""
    var password = ""

    // Sign-up fields
    var displayName = ""
    var confirmPassword = ""

    // Apple Sign-In pending credentials (stored while user picks a username)
    var pendingAppleUid: String?
    var pendingAppleEmail: String?

    var isFormValid: Bool {
        switch mode {
        case .login:
            return email.isValidEmail && password.isValidPassword
        case .signUp:
            return email.isValidEmail
                && password.isValidPassword
                && displayName.isValidDisplayName
                && password == confirmPassword
        case .usernameSetup:
            return displayName.isValidDisplayName
        }
    }

    var errorMessage: String? {
        if case .error(let msg) = state { return msg }
        return nil
    }

    func signIn(appState: AppState) async {
        state = .loading
        do {
            try await appState.authService.signIn(email: email, password: password)
            if let uid = appState.authService.currentUser?.uid {
                await appState.handleSignIn(uid: uid)
            }
            state = .idle
        } catch {
            print("[GeoQuest] Sign-in failed: \(error)")
            state = .error(error.localizedDescription)
        }
    }

    func signUp(appState: AppState) async {
        state = .loading
        do {
            let uid = try await appState.authService.signUp(
                email: email,
                password: password,
                displayName: displayName
            )
            try await appState.handleSignUp(uid: uid, email: email, displayName: displayName)
            state = .idle
        } catch {
            print("[GeoQuest] Sign-up failed: \(error)")
            state = .error(error.localizedDescription)
        }
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>, appState: AppState) async {
        state = .loading
        do {
            let authorization = try result.get()
            let (uid, email, displayName) = try await appState.authService.handleAppleSignIn(authorization: authorization)

            // Check if user profile exists
            if let _: GQUser = try await appState.userService.fetchUser(id: uid) {
                await appState.handleSignIn(uid: uid)
                state = .idle
            } else {
                // New user — let them choose a username
                pendingAppleUid = uid
                pendingAppleEmail = email
                self.displayName = displayName
                state = .idle
                withAnimation(GQTheme.smooth) {
                    mode = .usernameSetup
                }
            }
        } catch {
            print("[GeoQuest] Apple sign-in failed: \(error)")
            state = .error(error.localizedDescription)
        }
    }

    func completeUsernameSetup(appState: AppState) async {
        guard let uid = pendingAppleUid, let email = pendingAppleEmail else { return }
        state = .loading
        do {
            try await appState.handleSignUp(uid: uid, email: email, displayName: displayName.trimmingCharacters(in: .whitespaces))
            pendingAppleUid = nil
            pendingAppleEmail = nil
            state = .idle
        } catch {
            print("[GeoQuest] Username setup failed: \(error)")
            state = .error(error.localizedDescription)
        }
    }

    func prepareAppleSignIn() -> String {
        // This will be called from the AuthService
        return ""
    }

    func clearError() {
        state = .idle
    }

    func clearFields() {
        email = ""
        password = ""
        displayName = ""
        confirmPassword = ""
        pendingAppleUid = nil
        pendingAppleEmail = nil
        state = .idle
    }
}
