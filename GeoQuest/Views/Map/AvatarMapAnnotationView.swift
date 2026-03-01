import SwiftUI

struct AvatarMapAnnotationView: View {
    let config: AvatarConfig?
    var isMoving: Bool = false
    var movementHeading: Float = 0

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Pulse ring
            Circle()
                .stroke(GQTheme.primary.opacity(0.3), lineWidth: 2)
                .frame(width: 72, height: 72)
                .scaleEffect(isPulsing ? 1.4 : 1.0)
                .opacity(isPulsing ? 0.0 : 0.6)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: false),
                    value: isPulsing
                )

            // Direction indicator when walking
            if isMoving {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(GQTheme.primary)
                    .offset(y: -42)
                    .rotationEffect(.radians(Double(movementHeading)))
            }

            // 3D Avatar or fallback
            if let config {
                Avatar3DMapView(
                    config: config,
                    isWalking: isMoving,
                    facingAngle: movementHeading
                )
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            isMoving ? GQTheme.success : GQTheme.primary,
                            lineWidth: 3
                        )
                )
                .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
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
