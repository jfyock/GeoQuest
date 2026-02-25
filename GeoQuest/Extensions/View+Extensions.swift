import SwiftUI

extension View {
    func gqCard() -> some View {
        self
            .padding(GQTheme.paddingMedium)
            .background(GQTheme.cardBackground, in: RoundedRectangle(cornerRadius: GQTheme.cornerRadius))
    }

    func gqShadow() -> some View {
        self.shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    func gqTitle() -> some View {
        self.font(GQTheme.titleFont)
    }

    func gqHeadline() -> some View {
        self.font(GQTheme.headlineFont)
    }

    func gqBody() -> some View {
        self.font(GQTheme.bodyFont)
    }

    func gqCaption() -> some View {
        self.font(GQTheme.captionFont)
    }
}
