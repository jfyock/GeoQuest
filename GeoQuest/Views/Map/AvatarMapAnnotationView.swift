import SwiftUI

struct AvatarMapAnnotationView: View {
    let config: AvatarConfig?
    var isMoving: Bool = false
    var movementHeading: Float = 0
    /// Current map camera heading in degrees, so the avatar faces correctly
    /// regardless of map rotation.
    var mapHeading: Double = 0
    /// Scale factor driven by map zoom level (0.6x zoomed out – 1.5x zoomed in).
    var zoomScale: CGFloat = 1.0
    /// Emote to play on the avatar, if any.
    var emote: EmoteType?

    var body: some View {
        ZStack {
            // Emote speech bubble above the avatar
            if let emote {
                HStack(spacing: 4) {
                    Image(systemName: emote.iconName)
                        .font(.system(size: 14, weight: .bold))
                    Text(emote.displayName)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(GQTheme.accent, in: Capsule())
                .offset(y: -56)
                .transition(.scale.combined(with: .opacity))
                .animation(GQTheme.bouncy, value: emote)
            }

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
                    mapHeading: mapHeading,
                    emote: emote
                )
                .id(emote?.rawValue ?? "idle")
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
        .scaleEffect(zoomScale)
        .animation(GQTheme.smooth, value: zoomScale)
    }
}
