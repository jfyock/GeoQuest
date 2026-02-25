import SwiftUI

struct GQLoadingIndicator: View {
    var message: String = "Loading..."
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.north.fill")
                .font(.system(size: 32))
                .foregroundStyle(GQTheme.primary)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 1.5).repeatForever(autoreverses: false),
                    value: isAnimating
                )

            Text(message)
                .font(GQTheme.captionFont)
                .foregroundStyle(.secondary)
        }
        .onAppear { isAnimating = true }
    }
}
