import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Bindable var viewModel: AuthViewModel
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: GQTheme.paddingLarge) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "map.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(GQTheme.primary)
                    .symbolEffect(.bounce, options: .nonRepeating)

                Text("Welcome Back")
                    .font(GQTheme.titleFont)

                Text("Sign in to continue your adventure")
                    .font(GQTheme.bodyFont)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)

            // Form
            VStack(spacing: 14) {
                GQTextField(placeholder: "Email", text: $viewModel.email, icon: "envelope.fill")
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)

                GQTextField(placeholder: "Password", text: $viewModel.password, icon: "lock.fill", isSecure: true)
            }

            // Error
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(GQTheme.captionFont)
                    .foregroundStyle(GQTheme.error)
                    .multilineTextAlignment(.center)
            }

            // Sign In Button
            GQGameButton(
                title: "Sign In",
                icon: "arrow.right",
                color: GQTheme.primary,
                isLoading: isLoading,
                isDisabled: !viewModel.isFormValid
            ) {
                Task { await viewModel.signIn(appState: appState) }
            }

            // Divider
            HStack {
                Rectangle().fill(.secondary.opacity(0.3)).frame(height: 1)
                Text("or").font(GQTheme.captionFont).foregroundStyle(.secondary)
                Rectangle().fill(.secondary.opacity(0.3)).frame(height: 1)
            }

            // Apple Sign In
            SignInWithAppleButton(.signIn) { request in
                let nonce = appState.authService.prepareAppleSignIn()
                request.requestedScopes = [.email, .fullName]
                request.nonce = nonce
            } onCompletion: { result in
                Task { await viewModel.handleAppleSignIn(result: result, appState: appState) }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: GQTheme.buttonHeight)
            .clipShape(RoundedRectangle(cornerRadius: GQTheme.cornerRadius))

            Spacer()

            // Switch to Sign Up
            Button {
                withAnimation(GQTheme.smooth) {
                    viewModel.mode = .signUp
                    viewModel.clearFields()
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundStyle(.secondary)
                    Text("Sign Up")
                        .foregroundStyle(GQTheme.primary)
                        .fontWeight(.semibold)
                }
                .font(GQTheme.bodyFont)
            }
        }
        .padding(.horizontal, GQTheme.paddingLarge)
    }

    private var isLoading: Bool {
        if case .loading = viewModel.state { return true }
        return false
    }
}
