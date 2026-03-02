import SwiftUI

struct AvatarMapAnnotationView: View {
    let config: AvatarConfig?
    var isMoving: Bool = false
    var movementHeading: Float = 0
    /// Current map camera heading in degrees, so the avatar faces correctly
    /// regardless of map rotation.
    var mapHeading: Double = 0

    var body: some View {
        ZStack {
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
                    facingAngle: movementHeading,
                    mapHeading: mapHeading
                )
                .frame(width: 72, height: 80)
                .overlay(alignment: .bottom) {
                    // Small shadow ellipse under the avatar's feet
                    Ellipse()
                        .fill(.black.opacity(0.18))
                        .frame(width: 36, height: 10)
                        .blur(radius: 3)
                        .offset(y: 4)
                }
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
    }
}
