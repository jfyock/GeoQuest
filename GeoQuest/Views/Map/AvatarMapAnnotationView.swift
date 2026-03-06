import SwiftUI

struct AvatarMapAnnotationView: View {
    let config: AvatarConfig?
    var isMoving: Bool = false
    /// Device compass heading in radians (0 = north, clockwise).
    /// Used for avatar facing direction — independent of map rotation.
    var compassHeading: Float = 0
    /// Current map camera heading in degrees, so the avatar faces correctly
    /// regardless of map rotation.
    var mapHeading: Double = 0
    /// Current map camera pitch in degrees (0 = top-down, 90 = horizon).
    /// Controls avatar X-rotation so it's perpendicular to the map ground plane.
    var cameraPitch: Double = 0
    /// Scale factor driven by map zoom level.
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
                    .rotationEffect(.radians(Double(compassHeading)))
            }

            // 3D Avatar or fallback
            if let config {
                Avatar3DMapView(
                    config: config,
                    isWalking: isMoving,
                    compassHeading: compassHeading,
                    mapHeading: mapHeading,
                    cameraPitch: cameraPitch,
                    emote: emote
                )
                .id("\(config.hashValue)_\(emote?.rawValue ?? "idle")")
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
