import SwiftUI

struct IconPickerView: View {
    @Binding var selectedIcon: String
    var iconColor: Color = GQTheme.primary

    private let icons = [
        "mappin.circle.fill", "flag.fill", "star.fill", "heart.fill",
        "bolt.fill", "flame.fill", "leaf.fill", "tree.fill",
        "mountain.2.fill", "drop.fill", "sun.max.fill", "moon.fill",
        "sparkles", "diamond.fill", "shield.fill", "trophy.fill",
        "key.fill", "lock.fill", "book.fill", "scroll.fill",
        "binoculars.fill", "magnifyingglass", "puzzlepiece.fill", "crown.fill",
        "gift.fill", "camera.fill", "music.note", "globe.americas.fill",
        "building.2.fill", "figure.walk"
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(icons, id: \.self) { icon in
                Button {
                    withAnimation(GQTheme.bouncyQuick) {
                        selectedIcon = icon
                    }
                } label: {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(selectedIcon == icon ? .white : iconColor)
                        .frame(width: 44, height: 44)
                        .background(
                            selectedIcon == icon ? iconColor : iconColor.opacity(0.1),
                            in: RoundedRectangle(cornerRadius: GQTheme.cornerRadiusSmall)
                        )
                }
                .buttonStyle(BouncyScaleStyle())
            }
        }
    }
}
