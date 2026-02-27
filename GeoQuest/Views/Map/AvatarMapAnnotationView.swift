import SwiftUI

/// The player's position marker on the map.
///
/// Rendering priority:
///   1. `map_marker_player.glb` present → renders the 3D player pin (ignores avatar config,
///      keeping the annotation small and readable at map scale).
///   2. GLB not present but `avatar_body_default.glb` available → renders the player's
///      3D avatar via `AvatarPreviewView` (which switches to 3D automatically).
///   3. Neither → 2D `AvatarPreviewView` / default circle fallback (original behaviour).
///
/// The pulsing ring is always shown in all three cases.
struct AvatarMapAnnotationView: View {
    let config: AvatarConfig?
    @State private var isPulsing = false

    private var hasPlayerMarkerGLB: Bool {
        GLBAssetLoader.shared.isAvailable(named: "map_marker_player")
    }

    var body: some View {
        ZStack {
            // Pulsing ring — present in all rendering modes
            Circle()
                .stroke(GQTheme.primary.opacity(0.3), lineWidth: 2)
                .frame(width: 56, height: 56)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0.0 : 0.6)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: false),
                    value: isPulsing
                )

            markerContent
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
        .onAppear { isPulsing = true }
    }

    @ViewBuilder
    private var markerContent: some View {
        if hasPlayerMarkerGLB {
            // 3D player pin from GLB
            MapMarker3DView(
                modelName: "map_marker_player",
                cameraY: 1.5,
                cameraZ: 2.2
            )
            .frame(width: AppConstants.avatarMapSize, height: AppConstants.avatarMapSize)
            .clipShape(Circle())
        } else if let config {
            // 3D avatar (if body GLB present) or 2D avatar fallback
            AvatarPreviewView(config: config, size: AppConstants.avatarMapSize)
        } else {
            // Default — no avatar config available
            Circle()
                .fill(GQTheme.primary)
                .frame(width: AppConstants.avatarMapSize, height: AppConstants.avatarMapSize)
                .overlay {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
        }
    }
}
