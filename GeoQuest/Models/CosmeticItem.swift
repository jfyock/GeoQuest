import SwiftUI

enum CosmeticCategory: String, Codable, CaseIterable, Sendable {
    case skin, accessory, emote
}

enum CosmeticRarity: String, Codable, CaseIterable, Sendable {
    case common, uncommon, rare, epic, legendary

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return GQTheme.success
        case .rare: return GQTheme.primary
        case .epic: return GQTheme.secondary
        case .legendary: return GQTheme.gold
        }
    }

    /// Relative drop weight for random reward rolls. Lower = rarer.
    var dropWeight: Double {
        switch self {
        case .common: return 0.50
        case .uncommon: return 0.25
        case .rare: return 0.15
        case .epic: return 0.08
        case .legendary: return 0.02
        }
    }
}

struct CosmeticItem: Codable, Identifiable, Sendable {
    var id: String
    var name: String
    var description: String
    var category: CosmeticCategory
    var rarity: CosmeticRarity
    var iconName: String
    var modelFileName: String?
    var isDefault: Bool
    var isPurchasable: Bool
    var storeProductId: String?
    var priceInGems: Int?
    var accessoryType: String?
    var skinModelName: String?
    var emoteType: String?
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        category: CosmeticCategory,
        rarity: CosmeticRarity,
        iconName: String,
        modelFileName: String? = nil,
        isDefault: Bool = false,
        isPurchasable: Bool = false,
        storeProductId: String? = nil,
        priceInGems: Int? = nil,
        accessoryType: String? = nil,
        skinModelName: String? = nil,
        emoteType: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.rarity = rarity
        self.iconName = iconName
        self.modelFileName = modelFileName
        self.isDefault = isDefault
        self.isPurchasable = isPurchasable
        self.storeProductId = storeProductId
        self.priceInGems = priceInGems
        self.accessoryType = accessoryType
        self.skinModelName = skinModelName
        self.emoteType = emoteType
        self.createdAt = createdAt
    }
}
