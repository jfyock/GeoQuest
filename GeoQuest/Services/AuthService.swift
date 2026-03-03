import FirebaseAuth
import AuthenticationServices
import CryptoKit

@Observable
final class AuthService {
    private(set) var currentUser: FirebaseAuth.User?
    private(set) var isAuthenticated = false
    private(set) var isLoading = true

    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?

    func startListening() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
            self?.isLoading = false
        }
    }

    func stopListening() {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
            authStateListener = nil
        }
    }

    // MARK: - Email/Password

    func signUp(email: String, password: String, displayName: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()
        return result.user.uid
    }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    // MARK: - Apple Sign-In

    func handleAppleSignIn(authorization: ASAuthorization) async throws -> (uid: String, email: String, displayName: String) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthError.invalidCredential
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )
        let result = try await Auth.auth().signIn(with: credential)

        let email = result.user.email ?? appleIDCredential.email ?? ""
        let displayName = result.user.displayName
            ?? [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

        return (result.user.uid, email, displayName.isEmpty ? "Explorer" : displayName)
    }

    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    // MARK: - Sign Out

    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: - Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    deinit {
        stopListening()
    }
}

enum AuthError: LocalizedError {
    case invalidCredential
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Invalid sign-in credentials."
        case .userNotFound: return "User account not found."
        }
    }
}
