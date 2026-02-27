import SwiftUI

/// A map annotation pin for a single quest.
///
/// Renders purely in 2D — a coloured circle with a difficulty icon overlay.
/// The difficulty-colour dot and completion badge are SwiftUI overlays.
///
/// Note: 3D GLB quest markers are intentionally omitted. Each `RealityView`
/// instance creates its own Metal render context; with 10-15 simultaneous pins
/// this exhausts GPU memory (`CAMetalLayer nextDrawable` returning nil).
/// `Model3D`, which shares a context, is visionOS-only and unavailable on iOS.
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

                Circle()
                    .fill(data.iconColor)
                    .frame(width: 38, height: 38)

                Image(systemName: data.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

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
