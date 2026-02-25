import SwiftUI

struct GQButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = GQTheme.primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(GQTheme.headlineFont)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: GQTheme.buttonHeight)
            .background(
                isDisabled ? color.opacity(0.5) : color,
                in: RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
            )
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(isDisabled || isLoading)
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
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title)
                    .font(GQTheme.captionFont.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(color, in: Capsule())
        }
        .buttonStyle(BouncyButtonStyle())
    }
}
