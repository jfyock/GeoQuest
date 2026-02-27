import SwiftUI

struct GQTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var maxLength: Int? = nil
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 14) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isFocused ? GQTheme.primary : .secondary)
                    .frame(width: 24)
                    .animation(GQTheme.bouncyQuick, value: isFocused)
            }

            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .focused($isFocused)
            }

            if let maxLength {
                Text("\(text.count)/\(maxLength)")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(text.count >= maxLength ? GQTheme.error : Color(.tertiaryLabel))
            }
        }
        .padding(.horizontal, GQTheme.paddingMedium + 2)
        .frame(height: GQTheme.inputHeight)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: GQTheme.cornerRadiusSmall)
                    .fill(GQTheme.cardBackground)
                RoundedRectangle(cornerRadius: GQTheme.cornerRadiusSmall)
                    .stroke(
                        isFocused ? GQTheme.primary : Color.clear,
                        lineWidth: 2.5
                    )
            }
        )
        .shadow(
            color: isFocused ? GQTheme.primary.opacity(0.2) : .clear,
            radius: 8, x: 0, y: 2
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(GQTheme.bouncyQuick, value: isFocused)
        .onChange(of: text) { _, newValue in
            if let maxLength, newValue.count > maxLength {
                text = String(newValue.prefix(maxLength))
            }
        }
    }
}
