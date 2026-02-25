import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    @Bindable var viewModel: AuthViewModel
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: GQTheme.paddingLarge) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "globe.americas.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(GQTheme.accent)
                        .symbolEffect(.bounce, options: .nonRepeating)

                    Text("Join GeoQuest")
                        .font(GQTheme.titleFont)

                    Text("Create an account to start exploring")
                        .font(GQTheme.bodyFont)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // Form
                VStack(spacing: 14) {
                    GQTextField(placeholder: "Display Name", text: $viewModel.displayName, icon: "person.fill", maxLength: 30)
                        .textInputAutocapitalization(.words)

                    GQTextField(placeholder: "Email", text: $viewModel.email, icon: "envelope.fill")
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    GQTextField(placeholder: "Password (6+ characters)", text: $viewModel.password, icon: "lock.fill", isSecure: true)

                    GQTextField(placeholder: "Confirm Password", text: $viewModel.confirmPassword, icon: "lock.fill", isSecure: true)

                    if !viewModel.confirmPassword.isEmpty && viewModel.password != viewModel.confirmPassword {
                        Text("Passwords don't match")
                            .font(GQTheme.captionFont)
                            .foregroundStyle(GQTheme.error)
                    }
                }

                // Error
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(GQTheme.captionFont)
                        .foregroundStyle(GQTheme.error)
                        .multilineTextAlignment(.center)
                }

                // Sign Up Button
                GQButton(
                    title: "Create Account",
                    icon: "person.badge.plus",
                    color: GQTheme.accent,
                    isLoading: isLoading,
                    isDisabled: !viewModel.isFormValid
                ) {
                    Task { await viewModel.signUp(appState: appState) }
                }

                // Divider
                HStack {
                    Rectangle().fill(.secondary.opacity(0.3)).frame(height: 1)
                    Text("or").font(GQTheme.captionFont).foregroundStyle(.secondary)
                    Rectangle().fill(.secondary.opacity(0.3)).frame(height: 1)
                }

                // Apple Sign In
                SignInWithAppleButton(.signUp) { request in
                    let nonce = appState.authService.prepareAppleSignIn()
                    request.requestedScopes = [.email, .fullName]
                    request.nonce = nonce
                } onCompletion: { result in
                    Task { await viewModel.handleAppleSignIn(result: result, appState: appState) }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: GQTheme.buttonHeight)
                .clipShape(RoundedRectangle(cornerRadius: GQTheme.cornerRadius))

                // Switch to Login
                Button {
                    withAnimation(GQTheme.smooth) {
                        viewModel.mode = .login
                        viewModel.clearFields()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundStyle(.secondary)
                        Text("Sign In")
                            .foregroundStyle(GQTheme.primary)
                            .fontWeight(.semibold)
                    }
                    .font(GQTheme.bodyFont)
                }
                .padding(.bottom, GQTheme.paddingLarge)
            }
            .padding(.horizontal, GQTheme.paddingLarge)
        }
    }

    private var isLoading: Bool {
        if case .loading = viewModel.state { return true }
        return false
    }
}
