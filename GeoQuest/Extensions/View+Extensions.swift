import SwiftUI

extension View {
    func gqCard() -> some View {
        self
            .padding(GQTheme.paddingMedium)
            .background(GQTheme.cardBackground, in: RoundedRectangle(cornerRadius: GQTheme.cornerRadius))
    }

    func gqShadow() -> some View {
        self.shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
    }

    func gqCartoonShadow(color: Color = .black) -> some View {
        self.shadow(color: color.opacity(0.2), radius: 12, x: 0, y: 6)
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

    func gqDismissToolbar(dismiss: DismissAction, label: String = "Close") -> some View {
        self.toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(BouncyButtonStyle())
            }
        }
    }

    func gqMenuSheet() -> some View {
        self
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(GQTheme.cornerRadiusLarge)
    }
}
