import SwiftUI

/// Dramatic reveal overlay shown when a player earns a cosmetic drop after completing a quest.
struct CosmeticUnlockView: View {
    let item: CosmeticItem
    let onDismiss: () -> Void

    @State private var showGlow = false
    @State private var showItem = false
    @State private var showDetails = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: GQTheme.paddingLarge) {
                Spacer()

                // Rarity glow ring
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [item.rarity.color.opacity(0.6), item.rarity.color.opacity(0)],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(showGlow ? 1.2 : 0.3)
                        .opacity(showGlow ? 1 : 0)

                    // Rotating ring
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [item.rarity.color, item.rarity.color.opacity(0.3), item.rarity.color],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(showGlow ? 360 : 0))
                        .opacity(showGlow ? 1 : 0)

                    // Item icon
                    Image(systemName: item.iconName)
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(item.rarity.color)
                        .scaleEffect(showItem ? 1 : 0.1)
                        .opacity(showItem ? 1 : 0)
                }

                if showDetails {
                    // Item name
                    Text(item.name)
                        .font(GQTheme.titleFont)
                        .foregroundStyle(.white)

                    // Rarity badge
                    Text(item.rarity.displayName)
                        .font(GQTheme.headlineFont)
                        .foregroundStyle(item.rarity.color)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(item.rarity.color.opacity(0.2), in: Capsule())

                    // Category
                    Text(item.category.rawValue.capitalized)
                        .font(GQTheme.captionFont)
                        .foregroundStyle(.white.opacity(0.7))

                    // Description
                    Text(item.description)
                        .font(GQTheme.bodyFont)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, GQTheme.paddingLarge)
                }

                Spacer()

                if showDetails {
                    GQGameButton(title: "Awesome!", icon: "sparkles", color: item.rarity.color) {
                        onDismiss()
                    }
                    .padding(.horizontal, GQTheme.paddingLarge)
                    .padding(.bottom, GQTheme.paddingXLarge)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showGlow = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3)) {
                showItem = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.7)) {
                showDetails = true
            }
        }
    }
}
