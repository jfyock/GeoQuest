import SwiftUI

struct LoadingScreenView: View {
    @State private var viewModel = LoadingViewModel()
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background: try image first, fall back to color
            ZStack {
                viewModel.currentScreen.backgroundColor
                    .ignoresSafeArea()

                Image(viewModel.currentScreen.backgroundImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            // Dark overlay for readability
            LinearGradient(
                colors: [.black.opacity(0.3), .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                Image(systemName: viewModel.currentScreen.iconName)
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.3), radius: 16)
                    .symbolEffect(.bounce, options: .repeating.speed(0.4))
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Spacer().frame(height: 28)

                // Title
                Text(viewModel.currentScreen.title)
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 4, y: 2)

                Spacer().frame(height: 8)

                Text(viewModel.currentScreen.subtitle)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)

                Spacer()

                // Progress bar
                VStack(spacing: 16) {
                    // Cartoony progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Track
                            Capsule()
                                .fill(.white.opacity(0.2))
                                .frame(height: 14)

                            // Fill
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [GQTheme.success, GQTheme.teal],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: max(14, geometry.size.width * viewModel.progress),
                                    height: 14
                                )
                                .shadow(color: GQTheme.success.opacity(0.5), radius: 6)

                            // Highlight on fill
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.4), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(
                                    width: max(14, geometry.size.width * viewModel.progress),
                                    height: 7
                                )
                        }
                    }
                    .frame(height: 14)

                    Text(AppConstants.appName)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                        .tracking(2)
                        .textCase(.uppercase)
                }
                .padding(.horizontal, GQTheme.paddingXLarge)
                .padding(.bottom, 60)
            }
            .padding(.horizontal, GQTheme.paddingLarge)
        }
        .onAppear {
            viewModel.startRotation()
            withAnimation(GQTheme.bouncyHeavy) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
        .onDisappear {
            viewModel.completeProgress()
            viewModel.stopRotation()
        }
    }
}
