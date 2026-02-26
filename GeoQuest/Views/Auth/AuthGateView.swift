import SwiftUI

struct AuthGateView: View {
    @State private var viewModel = AuthViewModel()

    var body: some View {
        Group {
            switch viewModel.mode {
            case .login:
                LoginView(viewModel: viewModel)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            case .signUp:
                SignUpView(viewModel: viewModel)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .usernameSetup:
                UsernameSetupView(viewModel: viewModel)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(GQTheme.smooth, value: viewModel.mode)
    }
}
