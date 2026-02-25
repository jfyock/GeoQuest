import SwiftUI
import AuthenticationServices

@Observable
final class AuthViewModel {
    enum AuthMode {
        case login
        case signUp
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

    var isFormValid: Bool {
        switch mode {
        case .login:
            return email.isValidEmail && password.isValidPassword
        case .signUp:
            return email.isValidEmail
                && password.isValidPassword
                && displayName.isValidDisplayName
                && password == confirmPassword
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
            await appState.handleSignUp(uid: uid, email: email, displayName: displayName)
            state = .idle
        } catch {
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
            } else {
                await appState.handleSignUp(uid: uid, email: email, displayName: displayName)
            }
            state = .idle
        } catch {
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
        state = .idle
    }
}
