import SwiftUI

/// Main shop view with category tabs and a grid of purchasable cosmetic items.
struct ShopView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: CosmeticCategory = .skin
    @State private var selectedItem: CosmeticItem?

    private var cosmeticsService: CosmeticsService? { appState.cosmeticsService }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category tabs
                categoryTabs

                // Items grid
                ScrollView {
                    if let service = cosmeticsService {
                        let items = service.catalog.filter { $0.category == selectedCategory && !$0.isDefault }
                        if items.isEmpty {
                            emptyState
                        } else {
                            itemsGrid(items: items)
                        }
                    } else {
                        GQLoadingIndicator(message: "Loading shop...")
                    }
                }
            }
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    gemsDisplay
                }
            }
            .sheet(item: $selectedItem) { item in
                ShopItemDetailView(item: item)
                    .environment(appState)
            }
            .task {
                await cosmeticsService?.loadCatalog()
                await appState.storeService?.fetchProducts()
            }
        }
    }

    // MARK: - Category Tabs

    private var categoryTabs: some View {
        HStack(spacing: 0) {
            ForEach(CosmeticCategory.allCases, id: \.rawValue) { category in
                Button {
                    withAnimation(GQTheme.bouncyQuick) {
                        selectedCategory = category
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: categoryIcon(category))
                            .font(.system(size: 18, weight: .bold))
                        Text(category.rawValue.capitalized)
                            .font(GQTheme.caption2Font)
                    }
                    .foregroundStyle(selectedCategory == category ? GQTheme.primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        if selectedCategory == category {
                            RoundedRectangle(cornerRadius: GQTheme.cornerRadiusSmall)
                                .fill(GQTheme.primary.opacity(0.1))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, GQTheme.paddingMedium)
        .padding(.vertical, GQTheme.paddingSmall)
    }

    // MARK: - Items Grid

    private func itemsGrid(items: [CosmeticItem]) -> some View {
        let ownedIds = appState.currentUser?.ownedCosmeticIds ?? []

        return LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
            spacing: 14
        ) {
            ForEach(items) { item in
                ShopItemCard(
                    item: item,
                    isOwned: ownedIds.contains(item.id)
                ) {
                    selectedItem = item
                }
            }
        }
        .padding(GQTheme.paddingMedium)
    }

    // MARK: - Gems Display

    private var gemsDisplay: some View {
        HStack(spacing: 4) {
            Image(systemName: "diamond.fill")
                .foregroundStyle(GQTheme.teal)
            Text("\(appState.currentUser?.gems ?? 0)")
                .font(.system(.caption, design: .rounded, weight: .bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(GQTheme.cardBackground, in: Capsule())
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bag.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No items available")
                .font(GQTheme.headlineFont)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func categoryIcon(_ category: CosmeticCategory) -> String {
        switch category {
        case .skin: return "person.fill"
        case .accessory: return "crown.fill"
        case .emote: return "face.smiling.fill"
        }
    }
}

// MARK: - Shop Item Card

private struct ShopItemCard: View {
    let item: CosmeticItem
    let isOwned: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Icon
                ZStack {
                    Circle()
                        .fill(item.rarity.color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: item.iconName)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(item.rarity.color)
                }

                // Name
                Text(item.name)
                    .font(GQTheme.headlineFont)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                // Rarity
                Text(item.rarity.displayName)
                    .font(GQTheme.caption2Font)
                    .foregroundStyle(item.rarity.color)

                // Price or owned status
                if isOwned {
                    Text("Owned")
                        .font(GQTheme.caption2Font)
                        .foregroundStyle(GQTheme.success)
                } else if let gems = item.priceInGems {
                    HStack(spacing: 3) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(GQTheme.teal)
                        Text("\(gems)")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                    }
                } else if item.isPurchasable {
                    Text("IAP")
                        .font(GQTheme.caption2Font)
                        .foregroundStyle(GQTheme.accent)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, GQTheme.paddingMedium)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                        .fill(GQTheme.cardBackground)
                    RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                        .strokeBorder(item.rarity.color.opacity(0.3), lineWidth: 2)
                }
            )
        }
        .buttonStyle(BouncyButtonStyle())
        .opacity(isOwned ? 0.7 : 1.0)
    }
}
