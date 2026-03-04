import SwiftUI

/// Detail view for a shop item showing preview, description, rarity, and purchase button.
struct ShopItemDetailView: View {
    let item: CosmeticItem
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var purchaseResult: String?

    private var isOwned: Bool {
        appState.currentUser?.ownedCosmeticIds.contains(item.id) ?? false
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: GQTheme.paddingLarge) {
                    // Item preview
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [item.rarity.color.opacity(0.3), item.rarity.color.opacity(0.05)],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 180, height: 180)

                        Image(systemName: item.iconName)
                            .font(.system(size: 64, weight: .bold))
                            .foregroundStyle(item.rarity.color)
                    }
                    .padding(.top, GQTheme.paddingLarge)

                    // Name
                    Text(item.name)
                        .font(GQTheme.titleFont)

                    // Rarity badge
                    Text(item.rarity.displayName)
                        .font(GQTheme.headlineFont)
                        .foregroundStyle(item.rarity.color)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(item.rarity.color.opacity(0.15), in: Capsule())

                    // Description
                    GQCard {
                        Text(item.description)
                            .font(GQTheme.bodyFont)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Category info
                    HStack(spacing: 16) {
                        infoChip(label: "Category", value: item.category.rawValue.capitalized)
                        if let type = item.accessoryType ?? item.skinModelName ?? item.emoteType {
                            infoChip(label: "Type", value: type.capitalized)
                        }
                    }

                    Spacer(minLength: 20)

                    // Purchase / status button
                    if isOwned {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(GQTheme.success)
                            Text("Already Owned")
                                .font(GQTheme.headlineFont)
                                .foregroundStyle(GQTheme.success)
                        }
                    } else if let gems = item.priceInGems {
                        GQGameButton(
                            title: "Buy for \(gems) Gems",
                            icon: "diamond.fill",
                            color: GQTheme.teal,
                            isLoading: isPurchasing,
                            isDisabled: (appState.currentUser?.gems ?? 0) < gems
                        ) {
                            Task { await purchaseWithGems(cost: gems) }
                        }
                    } else if item.isPurchasable, let productId = item.storeProductId {
                        GQGameButton(
                            title: "Purchase",
                            icon: "cart.fill",
                            color: GQTheme.accent,
                            isLoading: isPurchasing
                        ) {
                            Task { await purchaseWithIAP(productId: productId) }
                        }
                    }

                    if let result = purchaseResult {
                        Text(result)
                            .font(GQTheme.captionFont)
                            .foregroundStyle(result.contains("Failed") ? GQTheme.error : GQTheme.success)
                    }
                }
                .padding(GQTheme.paddingLarge)
            }
            .navigationTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // MARK: - Purchase Flows

    private func purchaseWithGems(cost: Int) async {
        guard let user = appState.currentUser, user.gems >= cost else {
            purchaseResult = "Not enough gems!"
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            try await appState.cosmeticsService?.grantCosmetic(cosmeticId: item.id, userId: user.id, method: "gems")
            appState.currentUser?.gems -= cost
            appState.currentUser?.ownedCosmeticIds.append(item.id)
            purchaseResult = "Unlocked!"
        } catch {
            purchaseResult = "Failed: \(error.localizedDescription)"
        }
    }

    private func purchaseWithIAP(productId: String) async {
        isPurchasing = true
        defer { isPurchasing = false }

        if let purchasedId = await appState.storeService?.purchase(productId: productId) {
            guard let user = appState.currentUser else { return }
            do {
                try await appState.cosmeticsService?.grantCosmetic(cosmeticId: item.id, userId: user.id, method: "iap")
                appState.currentUser?.ownedCosmeticIds.append(item.id)
                purchaseResult = "Unlocked!"
            } catch {
                purchaseResult = "Failed to save purchase: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Helpers

    private func infoChip(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(GQTheme.caption2Font)
                .foregroundStyle(.secondary)
            Text(value)
                .font(GQTheme.captionFont)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(GQTheme.cardBackground, in: RoundedRectangle(cornerRadius: GQTheme.cornerRadiusSmall))
    }
}

