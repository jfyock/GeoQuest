import Foundation

struct AvatarConfig: Codable, Sendable, Equatable {
    var bodyColor: AvatarBodyColor
    var eyeStyle: AvatarEyeStyle
    var mouthStyle: AvatarMouthStyle
    var accessory: AvatarAccessory
    var backgroundColor: AvatarBackgroundColor

    static let `default` = AvatarConfig(
        bodyColor: .blue,
        eyeStyle: .normal,
        mouthStyle: .smile,
        accessory: .none,
        backgroundColor: .lightBlue
    )
}
