import SwiftUI

/// Grid of owned cosmetics where users can equip and unequip items.
struct CosmeticsInventoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: CosmeticCategory = .skin

    private var ownedItems: [CosmeticItem] {
        guard let user = appState.currentUser, let service = appState.cosmeticsService else { return [] }
        return service.ownedCosmetics(for: user).filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category tabs
                HStack(spacing: 0) {
                    ForEach(CosmeticCategory.allCases, id: \.rawValue) { category in
                        Button {
                            withAnimation(GQTheme.bouncyQuick) {
                                selectedCategory = category
                            }
                        } label: {
                            Text(category.rawValue.capitalized)
                                .font(GQTheme.captionFont)
                                .foregroundStyle(selectedCategory == category ? GQTheme.primary : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background {
                                    if selectedCategory == category {
                                        Capsule().fill(GQTheme.primary.opacity(0.1))
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, GQTheme.paddingMedium)
                .padding(.vertical, GQTheme.paddingSmall)

                // Items grid
                ScrollView {
                    if ownedItems.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "tray.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("No items yet")
                                .font(GQTheme.headlineFont)
                                .foregroundStyle(.secondary)
                            Text("Complete quests or visit the shop!")
                                .font(GQTheme.captionFont)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.top, 60)
                    } else {
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                            spacing: 12
                        ) {
                            ForEach(ownedItems) { item in
                                InventoryItemCell(item: item, isEquipped: isEquipped(item)) {
                                    toggleEquip(item)
                                }
                            }
                        }
                        .padding(GQTheme.paddingMedium)
                    }
                }
            }
            .navigationTitle("Cosmetics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func isEquipped(_ item: CosmeticItem) -> Bool {
        guard let user = appState.currentUser else { return false }
        switch item.category {
        case .skin:
            return user.avatarConfig.equippedSkinId == item.skinModelName
        case .accessory:
            return item.accessoryType == user.avatarConfig.accessory.rawValue
        case .emote:
            if let emoteType = item.emoteType {
                return user.avatarConfig.equippedEmotes.contains(emoteType)
            }
            return false
        }
    }

    private func toggleEquip(_ item: CosmeticItem) {
        guard appState.currentUser != nil else { return }
        withAnimation(GQTheme.bouncyQuick) {
            switch item.category {
            case .skin:
                if appState.currentUser?.avatarConfig.equippedSkinId == item.skinModelName {
                    appState.currentUser?.avatarConfig.equippedSkinId = nil
                } else {
                    appState.currentUser?.avatarConfig.equippedSkinId = item.skinModelName
                }
            case .accessory:
                // Accessories use the existing AvatarAccessory enum
                break
            case .emote:
                if let emoteType = item.emoteType {
                    if let index = appState.currentUser?.avatarConfig.equippedEmotes.firstIndex(of: emoteType) {
                        appState.currentUser?.avatarConfig.equippedEmotes.remove(at: index)
                    } else {
                        appState.currentUser?.avatarConfig.equippedEmotes.append(emoteType)
                    }
                }
            }
        }
    }
}

// MARK: - Inventory Item Cell

private struct InventoryItemCell: View {
    let item: CosmeticItem
    let isEquipped: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(item.rarity.color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: item.iconName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(item.rarity.color)

                    if isEquipped {
                        Circle()
                            .strokeBorder(GQTheme.success, lineWidth: 3)
                            .frame(width: 54, height: 54)
                    }
                }

                Text(item.name)
                    .font(GQTheme.caption2Font)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if isEquipped {
                    Text("Equipped")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(GQTheme.success)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: GQTheme.cornerRadiusSmall)
                    .fill(GQTheme.cardBackground)
            )
        }
        .buttonStyle(BouncyButtonStyle())
    }
}
