import SwiftUI

/// A map annotation pin for a single quest.
///
/// **3D mode** — active when the appropriate GLB for the quest's difficulty is in the bundle.
/// Falls back through the model priority chain before defaulting to the 2D implementation:
///
///   Difficulty → preferred model      → fallback model
///   .easy      → map_object_tree.glb  → map_marker_quest.glb → 2D icon
///   .medium    → map_marker_quest.glb → 2D icon
///   .hard      → map_object_chest.glb → map_marker_quest.glb → 2D icon
///   .expert    → map_object_flag.glb  → map_marker_quest.glb → 2D icon
///
/// The difficulty-colour dot and completion badge are always rendered as SwiftUI overlays
/// on top of either the 3D scene or the 2D fallback.
struct QuestAnnotationView: View {
    let data: QuestAnnotationData
    @State private var isAppearing = false

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Outer glow ring (both 2D and 3D)
                Circle()
                    .fill(data.iconColor.opacity(0.2))
                    .frame(width: 48, height: 48)

                if let modelName = resolvedModelName() {
                    // 3D quest marker
                    MapMarker3DView(
                        modelName: modelName,
                        tintColor: UIColor(data.iconColor),
                        cameraY: 1.4,
                        cameraZ: 2.0
                    )
                    .frame(width: 38, height: 38)
                    .clipShape(Circle())
                } else {
                    // 2D fallback — original design
                    Circle()
                        .fill(data.iconColor)
                        .frame(width: 38, height: 38)

                    Image(systemName: data.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                // Completion badge (always SwiftUI overlay)
                if data.isCompletedByCurrentUser {
                    Circle()
                        .fill(GQTheme.success)
                        .frame(width: 16, height: 16)
                        .overlay {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .offset(x: 16, y: -16)
                }

                // Difficulty dot (always SwiftUI overlay)
                Circle()
                    .fill(difficultyColor)
                    .frame(width: 10, height: 10)
                    .overlay {
                        Circle().strokeBorder(.white, lineWidth: 1.5)
                    }
                    .offset(x: -16, y: -16)
            }

            // Pointer triangle
            Image(systemName: "triangle.fill")
                .font(.system(size: 10))
                .foregroundStyle(data.iconColor)
                .rotationEffect(.degrees(180))
                .offset(y: -4)
        }
        .scaleEffect(isAppearing ? 1.0 : 0.3)
        .scaleEffect(data.isCompletedByCurrentUser ? 0.85 : 1.0)
        .opacity(data.isCompletedByCurrentUser ? 0.7 : 1.0)
        .onAppear {
            withAnimation(GQTheme.bouncy) {
                isAppearing = true
            }
        }
    }

    // MARK: - 3D Model Resolution

    /// Returns the best available GLB model name for this quest's difficulty,
    /// or nil when no suitable GLB is in the bundle (triggers 2D fallback).
    private func resolvedModelName() -> String? {
        let loader = GLBAssetLoader.shared

        switch data.difficulty {
        case .easy:
            if loader.isAvailable(named: "map_object_tree")  { return "map_object_tree" }
            if loader.isAvailable(named: "map_marker_quest") { return "map_marker_quest" }
            return nil

        case .medium:
            if loader.isAvailable(named: "map_marker_quest") { return "map_marker_quest" }
            return nil

        case .hard:
            if loader.isAvailable(named: "map_object_chest") { return "map_object_chest" }
            if loader.isAvailable(named: "map_marker_quest") { return "map_marker_quest" }
            return nil

        case .expert:
            if loader.isAvailable(named: "map_object_flag")  { return "map_object_flag" }
            if loader.isAvailable(named: "map_marker_quest") { return "map_marker_quest" }
            return nil
        }
    }

    // MARK: - Difficulty Colour

    private var difficultyColor: Color {
        switch data.difficulty {
        case .easy:   return GQTheme.easyColor
        case .medium: return GQTheme.mediumColor
        case .hard:   return GQTheme.hardColor
        case .expert: return GQTheme.expertColor
        }
    }
}
