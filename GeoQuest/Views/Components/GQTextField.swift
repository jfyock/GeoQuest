import SwiftUI

struct GQTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var maxLength: Int? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
            }

            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(GQTheme.bodyFont)
            } else {
                TextField(placeholder, text: $text)
                    .font(GQTheme.bodyFont)
            }

            if let maxLength {
                Text("\(text.count)/\(maxLength)")
                    .font(GQTheme.caption2Font)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(GQTheme.paddingMedium)
        .background(GQTheme.cardBackground, in: RoundedRectangle(cornerRadius: GQTheme.cornerRadiusSmall))
        .onChange(of: text) { _, newValue in
            if let maxLength, newValue.count > maxLength {
                text = String(newValue.prefix(maxLength))
            }
        }
    }
}
