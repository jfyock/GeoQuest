import Foundation

struct AvatarConfig: Codable, Sendable, Equatable, Hashable {
    var bodyColor: AvatarBodyColor
    var eyeStyle: AvatarEyeStyle
    var mouthStyle: AvatarMouthStyle
    var accessory: AvatarAccessory
    var backgroundColor: AvatarBackgroundColor
    var equippedSkinId: String?
    var equippedEmotes: [String]

    static let `default` = AvatarConfig(
        bodyColor: .blue,
        eyeStyle: .normal,
        mouthStyle: .smile,
        accessory: .none,
        backgroundColor: .lightBlue,
        equippedSkinId: nil,
        equippedEmotes: []
    )

    // Backward-compatible decoding: missing fields get defaults
    enum CodingKeys: String, CodingKey {
        case bodyColor, eyeStyle, mouthStyle, accessory, backgroundColor
        case equippedSkinId, equippedEmotes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bodyColor = try container.decode(AvatarBodyColor.self, forKey: .bodyColor)
        eyeStyle = try container.decode(AvatarEyeStyle.self, forKey: .eyeStyle)
        mouthStyle = try container.decode(AvatarMouthStyle.self, forKey: .mouthStyle)
        accessory = try container.decode(AvatarAccessory.self, forKey: .accessory)
        backgroundColor = try container.decode(AvatarBackgroundColor.self, forKey: .backgroundColor)
        equippedSkinId = try container.decodeIfPresent(String.self, forKey: .equippedSkinId)
        equippedEmotes = try container.decodeIfPresent([String].self, forKey: .equippedEmotes) ?? []
    }

    init(
        bodyColor: AvatarBodyColor,
        eyeStyle: AvatarEyeStyle,
        mouthStyle: AvatarMouthStyle,
        accessory: AvatarAccessory,
        backgroundColor: AvatarBackgroundColor,
        equippedSkinId: String? = nil,
        equippedEmotes: [String] = []
    ) {
        self.bodyColor = bodyColor
        self.eyeStyle = eyeStyle
        self.mouthStyle = mouthStyle
        self.accessory = accessory
        self.backgroundColor = backgroundColor
        self.equippedSkinId = equippedSkinId
        self.equippedEmotes = equippedEmotes
    }
}
