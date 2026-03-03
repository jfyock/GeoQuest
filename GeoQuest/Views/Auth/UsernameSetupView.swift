import SwiftUI

struct UsernameSetupView: View {
    @Bindable var viewModel: AuthViewModel
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: GQTheme.paddingLarge) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.text.rectangle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(GQTheme.accent)
                    .symbolEffect(.bounce, options: .nonRepeating)

                Text("Choose Your Name")
                    .font(GQTheme.titleFont)

                Text("Pick a display name other players will see")
                    .font(GQTheme.bodyFont)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            // Username field
            VStack(alignment: .leading, spacing: 8) {
                GQTextField(
                    placeholder: "Display Name",
                    text: $viewModel.displayName,
                    icon: "person.fill",
                    maxLength: 30
                )
                .textInputAutocapitalization(.words)

                Text("2-30 characters")
                    .font(GQTheme.caption2Font)
                    .foregroundStyle(.tertiary)
            }

            // Error
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(GQTheme.captionFont)
                    .foregroundStyle(GQTheme.error)
                    .multilineTextAlignment(.center)
            }

            // Continue button
            GQButton(
                title: "Let's Go!",
                icon: "arrow.right",
                color: GQTheme.accent,
                isLoading: isLoading,
                isDisabled: !viewModel.isFormValid
            ) {
                Task { await viewModel.completeUsernameSetup(appState: appState) }
            }

            Spacer()

            // Back button — sign out since Firebase Auth session was already created
            Button {
                appState.handleSignOut()
                withAnimation(GQTheme.smooth) {
                    viewModel.clearFields()
                    viewModel.mode = .login
                }
            } label: {
                Text("Cancel")
                    .font(GQTheme.bodyFont)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, GQTheme.paddingLarge)
    }

    private var isLoading: Bool {
        if case .loading = viewModel.state { return true }
        return false
    }
}
