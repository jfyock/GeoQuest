import SwiftUI

struct LoadingScreenView: View {
    @State private var viewModel = LoadingViewModel()
    @State private var iconBounce = false

    var body: some View {
        ZStack {
            viewModel.currentScreen.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image(systemName: viewModel.currentScreen.iconName)
                    .font(.system(size: 80, weight: .medium))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, options: .repeating.speed(0.5))

                VStack(spacing: 8) {
                    Text(viewModel.currentScreen.title)
                        .font(GQTheme.titleFont)
                        .foregroundStyle(.white)

                    Text(viewModel.currentScreen.subtitle)
                        .font(GQTheme.bodyFont)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.3)

                    Text(AppConstants.appName)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.bottom, 60)
            }
            .padding(.horizontal, GQTheme.paddingLarge)
        }
        .onAppear { viewModel.startRotation() }
        .onDisappear { viewModel.stopRotation() }
    }
}
