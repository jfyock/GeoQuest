import SwiftUI

/// Image-based game button that uses 9-slice background images for a hand-painted
/// Clash Royale / Fortnite-style look. Falls back to GQButton3D when image assets
/// are not available.
///
/// When `backgroundImage` is not provided, the button automatically looks for a
/// texture in the asset catalog based on the `color` parameter:
///   - GQTheme.primary  → "button_primary" / "button_primary_pressed"
///   - GQTheme.accent   → "button_primary" (shared orange/accent texture)
///   - GQTheme.success  → "button_success" / "button_success_pressed"
///   - GQTheme.error    → "button_danger"  / "button_danger_pressed"
///   - .gray            → "button_secondary" / "button_secondary_pressed"
///   - anything else    → "button_primary" / "button_primary_pressed"
///
/// If no matching asset is found, falls back to `GQButton3D` (programmatic 3D look).
struct GQGameButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = GQTheme.primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    /// Name of the normal-state background image in the asset catalog.
    /// When nil, auto-resolves based on `color`.
    var backgroundImage: String? = nil
    /// Name of the pressed-state background image in the asset catalog.
    /// When nil, auto-resolves based on `color`.
    var pressedBackgroundImage: String? = nil
    /// Optional badge text (e.g. "NEW") shown in the top-right corner.
    var badge: String? = nil
    /// Enable shimmer sweep overlay for call-to-action emphasis.
    var showShimmer: Bool = false
    let action: () -> Void

    @State private var isPressed = false
    @State private var shimmerOffset: CGFloat = -1.0

    /// Resolves the background image name, trying explicit → auto-detected → nil.
    private var resolvedBackground: String? {
        if let backgroundImage, UIImage(named: backgroundImage) != nil {
            return backgroundImage
        }
        let autoName = Self.autoImageName(for: color)
        if UIImage(named: autoName) != nil {
            return autoName
        }
        // Last resort: try "button_primary"
        if UIImage(named: "button_primary") != nil {
            return "button_primary"
        }
        return nil
    }

    private var resolvedPressedBackground: String? {
        if let pressedBackgroundImage, UIImage(named: pressedBackgroundImage) != nil {
            return pressedBackgroundImage
        }
        let autoName = Self.autoPressedImageName(for: color)
        if UIImage(named: autoName) != nil {
            return autoName
        }
        if UIImage(named: "button_primary_pressed") != nil {
            return "button_primary_pressed"
        }
        return nil
    }

    var body: some View {
        if let bg = resolvedBackground {
            imageBasedButton(normalImage: bg, pressedImage: resolvedPressedBackground ?? bg)
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

    private func imageBasedButton(normalImage: String, pressedImage: String) -> some View {
        Button(action: action) {
            ZStack {
                // 9-slice background
                let imgName = isPressed ? pressedImage : normalImage
                Image(imgName)
                    .resizable(capInsets: EdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30), resizingMode: .stretch)

                // Color tint overlay for non-standard colors
                if !Self.isStandardColor(color) {
                    RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                        .fill(color.opacity(0.35))
                        .blendMode(.sourceAtop)
                }

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

    // MARK: - Color → Image Name Mapping

    private static func autoImageName(for color: Color) -> String {
        switch color {
        case GQTheme.success: return "button_success"
        case GQTheme.error: return "button_danger"
        case .gray: return "button_secondary"
        default: return "button_primary"
        }
    }

    private static func autoPressedImageName(for color: Color) -> String {
        switch color {
        case GQTheme.success: return "button_success_pressed"
        case GQTheme.error: return "button_danger_pressed"
        case .gray: return "button_secondary_pressed"
        default: return "button_primary_pressed"
        }
    }

    /// Whether the color has a dedicated texture (no tint overlay needed).
    private static func isStandardColor(_ color: Color) -> Bool {
        color == GQTheme.primary || color == GQTheme.accent ||
        color == GQTheme.success || color == GQTheme.error || color == .gray
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
