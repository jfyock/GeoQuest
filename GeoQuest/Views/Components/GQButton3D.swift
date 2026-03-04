import SwiftUI

/// Code-based 3D button with a thick border, bottom edge depth effect, top bevel
/// highlight, and spring press animation. Used as the default game-style button
/// before image assets arrive.
struct GQButton3D: View {
    let title: String
    var icon: String? = nil
    var color: Color = GQTheme.primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    private var effectiveColor: Color {
        isDisabled ? .gray : color
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // 3D bottom edge (darker shade, offset down)
                RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                    .fill(effectiveColor.opacity(0.5))
                    .offset(y: isPressed ? 2 : GQTheme.button3DEdgeHeight)

                // Main button face
                RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                    .fill(effectiveColor)

                // Thick border with gradient
                RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [effectiveColor.opacity(0.8), effectiveColor.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: GQTheme.button3DBorderWidth
                    )

                // Top bevel highlight
                RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(isDisabled ? 0.1 : 0.35), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )

                // Inner highlight stroke
                RoundedRectangle(cornerRadius: GQTheme.cornerRadius - 2)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                    .padding(GQTheme.button3DBorderWidth / 2)

                // Content
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        if let icon {
                            Image(systemName: icon)
                                .font(.system(size: 20, weight: .bold))
                        }
                        Text(title)
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                    }
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: GQTheme.buttonHeight)
            .offset(y: isPressed ? GQTheme.button3DEdgeHeight - 2 : 0)
            .shadow(
                color: effectiveColor.opacity(isPressed ? 0.2 : 0.4),
                radius: isPressed ? 4 : 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
        }
        .buttonStyle(Button3DPressStyle(isPressed: $isPressed))
        .disabled(isDisabled || isLoading)
        // Reserve space for the 3D edge so layout doesn't shift on press
        .padding(.bottom, GQTheme.button3DEdgeHeight)
    }
}

/// Button style that tracks press state and applies a spring push-down animation.
private struct Button3DPressStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.55)) {
                    isPressed = pressed
                }
            }
    }
}
