import SwiftUI

/// Image-based game button that uses 9-slice background images for a hand-painted
/// Clash Royale / Fortnite-style look. Falls back to GQButton3D when image assets
/// are not available.
struct GQGameButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = GQTheme.primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    /// Name of the normal-state background image in the asset catalog.
    var backgroundImage: String? = nil
    /// Name of the pressed-state background image in the asset catalog.
    var pressedBackgroundImage: String? = nil
    /// Optional badge text (e.g. "NEW") shown in the top-right corner.
    var badge: String? = nil
    /// Enable shimmer sweep overlay for call-to-action emphasis.
    var showShimmer: Bool = false
    let action: () -> Void

    @State private var isPressed = false
    @State private var shimmerOffset: CGFloat = -1.0

    var body: some View {
        let hasImages = backgroundImage != nil
            && UIImage(named: backgroundImage!) != nil

        if hasImages {
            imageBasedButton
        } else {
            GQButton3D(
                title: title,
                icon: icon,
                color: color,
                isLoading: isLoading,
                isDisabled: isDisabled,
                action: action
            )
        }
    }

    // MARK: - Image-based button

    private var imageBasedButton: some View {
        Button(action: action) {
            ZStack {
                // 9-slice background
                let imgName = isPressed ? (pressedBackgroundImage ?? backgroundImage!) : backgroundImage!
                Image(imgName)
                    .resizable(capInsets: EdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30), resizingMode: .stretch)

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
                .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)

                // Shimmer overlay
                if showShimmer {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.25), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * 0.4)
                            .offset(x: shimmerOffset * geo.size.width)
                            .onAppear {
                                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                                    shimmerOffset = 1.4
                                }
                            }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: GQTheme.cornerRadius))
                }

                // Badge
                if let badge {
                    Text(badge)
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(GQTheme.error, in: Capsule())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .offset(x: -4, y: -4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: GQTheme.buttonHeight)
            .offset(y: isPressed ? 3 : 0)
        }
        .buttonStyle(GameImageButtonStyle(isPressed: $isPressed))
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

/// Custom button style that tracks press state for image-based buttons.
private struct GameImageButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
                    isPressed = pressed
                }
            }
    }
}
