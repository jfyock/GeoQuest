import SwiftUI

struct AvatarMapAnnotationView: View {
    let config: AvatarConfig?
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Pulse ring
            Circle()
                .stroke(GQTheme.primary.opacity(0.3), lineWidth: 2)
                .frame(width: 56, height: 56)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0.0 : 0.6)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: false),
                    value: isPulsing
                )

            // Avatar or default marker
            if let config {
                AvatarPreviewView(config: config, size: AppConstants.avatarMapSize)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            } else {
                Circle()
                    .fill(GQTheme.primary)
                    .frame(width: AppConstants.avatarMapSize, height: AppConstants.avatarMapSize)
                    .overlay {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            }
        }
        .onAppear { isPulsing = true }
    }
}
