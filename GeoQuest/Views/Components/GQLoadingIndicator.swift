import SwiftUI

struct GQLoadingIndicator: View {
    var message: String = "Loading..."
    @State private var isAnimating = false
    @State private var bouncePhase = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "location.north.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(GQTheme.primary)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .scaleEffect(bouncePhase ? 1.1 : 0.9)
                .shadow(color: GQTheme.primary.opacity(0.3), radius: 8)
                .animation(
                    .linear(duration: 1.5).repeatForever(autoreverses: false),
                    value: isAnimating
                )
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: bouncePhase
                )

            Text(message)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .onAppear {
            isAnimating = true
            bouncePhase = true
        }
    }
}
