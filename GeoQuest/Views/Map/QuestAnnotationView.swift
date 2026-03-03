import SwiftUI

struct QuestAnnotationView: View {
    let data: QuestAnnotationData
    @State private var isAppearing = false

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(data.iconColor.opacity(0.2))
                    .frame(width: 48, height: 48)

                // Main circle
                Circle()
                    .fill(data.iconColor)
                    .frame(width: 38, height: 38)

                // Icon
                Image(systemName: data.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                // Completed checkmark
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

                // Difficulty indicator
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

    private var difficultyColor: Color {
        switch data.difficulty {
        case .easy: return GQTheme.easyColor
        case .medium: return GQTheme.mediumColor
        case .hard: return GQTheme.hardColor
        case .expert: return GQTheme.expertColor
        }
    }
}
