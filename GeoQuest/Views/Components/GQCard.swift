import SwiftUI

struct GQCard<Content: View>: View {
    var padding: CGFloat = GQTheme.paddingMedium
    var accentColor: Color? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                    .fill(GQTheme.cardBackground)
                if let accentColor {
                    RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                        .stroke(accentColor.opacity(0.2), lineWidth: 2)
                }
            }
        )
        .gqShadow()
    }
}
