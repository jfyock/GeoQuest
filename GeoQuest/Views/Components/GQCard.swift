import SwiftUI

struct GQCard<Content: View>: View {
    var padding: CGFloat = GQTheme.paddingMedium
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GQTheme.cardBackground, in: RoundedRectangle(cornerRadius: GQTheme.cornerRadius))
        .gqShadow()
    }
}
