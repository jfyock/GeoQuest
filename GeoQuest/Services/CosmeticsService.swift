import Foundation

/// Manages the cosmetics catalog and user-owned cosmetics.
@Observable
final class CosmeticsService {
    private(set) var catalog: [CosmeticItem] = []
    private(set) var isLoading = false

    private let firestoreService: FirestoreService
    private let userService: UserService

    init(firestoreService: FirestoreService, userService: UserService) {
        self.firestoreService = firestoreService
        self.userService = userService
    }

    /// Fetches all cosmetic items from the Firestore `cosmetics` collection.
    func loadCatalog() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let items: [CosmeticItem] = try await firestoreService.fetchCollection(
                AppConstants.Collections.cosmetics
            )
            catalog = items.isEmpty ? Self.defaultCatalog : items
        } catch {
            print("[CosmeticsService] Failed to load catalog: \(error)")
            // Use built-in defaults as fallback
            catalog = Self.defaultCatalog
        }
    }

    /// Grants a cosmetic item to a user.
    func grantCosmetic(cosmeticId: String, userId: String, method: String = "drop") async throws {
        try await firestoreService.appendToArray(
            collection: AppConstants.Collections.users,
            documentId: userId,
            field: "ownedCosmeticIds",
            value: cosmeticId
        )
    }

    /// Returns cosmetics owned by a user (including defaults).
    func ownedCosmetics(for user: GQUser) -> [CosmeticItem] {
        let defaults = catalog.filter { $0.isDefault }
        let owned = catalog.filter { user.ownedCosmeticIds.contains($0.id) }
        return defaults + owned.filter { !$0.isDefault }
    }

    /// Performs a weighted random drop roll, excluding already-owned items.
    func rollRandomDrop(excluding ownedIds: [String]) -> CosmeticItem? {
        let droppable = catalog.filter { !$0.isDefault && !ownedIds.contains($0.id) }
        guard !droppable.isEmpty else { return nil }

        let totalWeight = droppable.reduce(0.0) { $0 + $1.rarity.dropWeight }
        var random = Double.random(in: 0..<totalWeight)

        for item in droppable {
            random -= item.rarity.dropWeight
            if random <= 0 {
                return item
            }
        }

        return droppable.last
    }

    // MARK: - Default Catalog

    static let defaultCatalog: [CosmeticItem] = [
        CosmeticItem(id: "skin_default", name: "Classic", description: "The default character look", category: .skin, rarity: .common, iconName: "person.fill", isDefault: true),
        CosmeticItem(id: "skin_knight", name: "Knight", description: "Medieval knight armor", category: .skin, rarity: .rare, iconName: "shield.fill", skinModelName: "knight"),
        CosmeticItem(id: "skin_pirate", name: "Pirate", description: "Arrr! A salty sea dog", category: .skin, rarity: .rare, iconName: "flag.fill", skinModelName: "pirate"),
        CosmeticItem(id: "skin_space", name: "Astronaut", description: "One small step for quests", category: .skin, rarity: .epic, iconName: "airplane", skinModelName: "space"),
        CosmeticItem(id: "acc_viking", name: "Viking Helmet", description: "Horned helmet of the north", category: .accessory, rarity: .uncommon, iconName: "crown.fill", accessoryType: "hat"),
        CosmeticItem(id: "acc_wizard", name: "Wizard Hat", description: "Magical and mysterious", category: .accessory, rarity: .rare, iconName: "wand.and.stars", accessoryType: "hat"),
        CosmeticItem(id: "acc_ninja", name: "Ninja Headband", description: "Silent and swift", category: .accessory, rarity: .uncommon, iconName: "wind", accessoryType: "headband"),
        CosmeticItem(id: "emote_wave", name: "Wave", description: "Say hello!", category: .emote, rarity: .common, iconName: "hand.wave.fill", isDefault: true, emoteType: "wave"),
        CosmeticItem(id: "emote_dance", name: "Dance", description: "Show your moves!", category: .emote, rarity: .uncommon, iconName: "figure.dance", emoteType: "dance"),
        CosmeticItem(id: "emote_celebrate", name: "Celebrate", description: "Party time!", category: .emote, rarity: .uncommon, iconName: "party.popper.fill", emoteType: "celebrate"),
        CosmeticItem(id: "emote_clap", name: "Clap", description: "Round of applause", category: .emote, rarity: .common, iconName: "hands.clap.fill", isDefault: true, emoteType: "clap"),
        CosmeticItem(id: "emote_flex", name: "Flex", description: "Show off your muscles", category: .emote, rarity: .rare, iconName: "figure.strengthtraining.traditional", emoteType: "flex"),
        CosmeticItem(id: "emote_spin", name: "Spin", description: "Spin to win!", category: .emote, rarity: .uncommon, iconName: "arrow.triangle.2.circlepath", emoteType: "spin"),
        CosmeticItem(id: "emote_bow", name: "Bow", description: "A noble gesture", category: .emote, rarity: .rare, iconName: "figure.cooldown", emoteType: "bow"),
        CosmeticItem(id: "emote_shrug", name: "Shrug", description: "Who knows?", category: .emote, rarity: .common, iconName: "person.crop.circle.badge.questionmark.fill", isDefault: true, emoteType: "shrug"),
    ]
}
