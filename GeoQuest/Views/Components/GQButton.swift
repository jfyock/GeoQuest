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
            .frame(maxWidth: .infinity)
            .frame(height: GQTheme.buttonHeight)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                        .fill(isDisabled ? color.opacity(0.4) : color)
                    RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                    RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                        .stroke(color.opacity(0.6), lineWidth: 3)
                        .offset(y: 2)
                        .clipShape(RoundedRectangle(cornerRadius: GQTheme.cornerRadius))
                }
            )
            .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
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
                        .font(.system(size: 14, weight: .bold))
                }
                Text(title)
                    .font(.system(.caption, design: .rounded, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
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
            )
            .shadow(color: color.opacity(0.35), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(BouncyButtonStyle())
    }
}
