import SwiftUI

/// Grid overlay of available emote buttons shown on the map.
struct EmoteMenuView: View {
    let availableEmotes: [EmoteType]
    let onSelectEmote: (EmoteType) -> Void
    let onDismiss: () -> Void

    @State private var appeared = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            // Tap outside to dismiss
            Color.black.opacity(0.01)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack {
                Spacer()

                VStack(spacing: 12) {
                    // Header
                    HStack {
                        Text("Emotes")
                            .font(GQTheme.headlineFont)
                        Spacer()
                        Button {
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Emote grid
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(availableEmotes.enumerated()), id: \.element.id) { index, emote in
                            Button {
                                onSelectEmote(emote)
                                onDismiss()
                            } label: {
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(GQTheme.cardBackground)
                                            .frame(width: 52, height: 52)
                                        Image(systemName: emote.iconName)
                                            .font(.system(size: 22))
                                            .foregroundStyle(GQTheme.accent)
                                    }
                                    Text(emote.displayName)
                                        .font(GQTheme.caption2Font)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(BouncyButtonStyle())
                            .scaleEffect(appeared ? 1 : 0.3)
                            .opacity(appeared ? 1 : 0)
                            .animation(
                                GQTheme.bouncy.delay(Double(index) * 0.04),
                                value: appeared
                            )
                        }
                    }
                }
                .padding(GQTheme.paddingMedium)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: GQTheme.cornerRadiusLarge))
                .padding(.horizontal, GQTheme.paddingMedium)
                .padding(.bottom, GQTheme.paddingLarge)
            }
        }
        .onAppear {
            withAnimation(GQTheme.bouncy) {
                appeared = true
            }
        }
    }
}
