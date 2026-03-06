import SwiftUI

/// Standard full-width button. Delegates to GQGameButton so all buttons
/// automatically pick up texture assets from the catalog when available.
struct GQButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = GQTheme.primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        GQGameButton(
            title: title,
            icon: icon,
            color: color,
            isLoading: isLoading,
            isDisabled: isDisabled,
            action: action
        )
    }
}

struct GQButtonSmall: View {
    let title: String
    var icon: String? = nil
    var color: Color = GQTheme.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                }
                Text(title)
                    .font(.system(.caption, design: .rounded, weight: .bold))
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background {
                if let imgName = resolvedImage, UIImage(named: imgName) != nil {
                    Image(imgName)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Capsule().fill(color)
                        Capsule().fill(
                            LinearGradient(
                                colors: [.white.opacity(0.25), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                    }
                }
            }
            .clipShape(Capsule())
            .shadow(color: color.opacity(0.35), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(BouncyButtonStyle())
    }

    private var resolvedImage: String? {
        switch color {
        case GQTheme.success: return "button_success"
        case GQTheme.error: return "button_danger"
        case .gray: return "button_secondary"
        default: return "button_primary"
        }
    }
}
