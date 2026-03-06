import SwiftUI

struct QuestAnnotationView: View {
    let data: QuestAnnotationData
    var cameraPitch: Double = 0
    var zoomScale: CGFloat = 1.0
    @State private var isAppearing = false

    var body: some View {
        ZStack {
            // 3D marker rendered via SceneKit with camera orbit
            MapElement3DView(
                type: .questMarker(
                    red: colorComponents.red,
                    green: colorComponents.green,
                    blue: colorComponents.blue,
                    isCompleted: data.isCompletedByCurrentUser
                ),
                cameraPitch: cameraPitch
            )
            .frame(width: 48, height: 56)

            // Difficulty indicator — small colored dot at top-right
            Circle()
                .fill(difficultyColor)
                .frame(width: 10, height: 10)
                .overlay {
                    Circle().strokeBorder(.white, lineWidth: 1.5)
                }
                .offset(x: 18, y: -22)
        }
        .scaleEffect(isAppearing ? 1.0 : 0.3)
        .scaleEffect(zoomScale)
        .scaleEffect(data.isCompletedByCurrentUser ? 0.85 : 1.0)
        .opacity(data.isCompletedByCurrentUser ? 0.7 : 1.0)
        .onAppear {
            withAnimation(GQTheme.bouncy) {
                isAppearing = true
            }
        }
    }

    /// Extracts RGB components from the quest icon color for SceneKit.
    private var colorComponents: (red: CGFloat, green: CGFloat, blue: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        UIColor(data.iconColor).getRed(&r, green: &g, blue: &b, alpha: nil)
        return (r, g, b)
    }

    private var difficultyColor: Color {
        switch data.difficulty {
        case .easy: return GQTheme.easyColor
        case .medium: return GQTheme.mediumColor
        case .hard: return GQTheme.hardColor
        case .expert: return GQTheme.expertColor
        }
    }
}
