import Foundation

enum AvatarBodyColor: String, Codable, CaseIterable, Sendable {
    case red, orange, yellow, green, blue, indigo, purple, pink, teal, mint, cyan, brown
}

enum AvatarEyeStyle: String, Codable, CaseIterable, Sendable {
    case normal, happy, cool, surprised, sleepy, wink, stars, hearts
}

enum AvatarMouthStyle: String, Codable, CaseIterable, Sendable {
    case smile, grin, neutral, open, tongue, cat, smirk
}

enum AvatarAccessory: String, Codable, CaseIterable, Sendable {
    case none, hat, crown, glasses, sunglasses, headband, antenna, bow
}

enum AvatarBackgroundColor: String, Codable, CaseIterable, Sendable {
    case lightBlue, lightGreen, lightPink, lightYellow, lightPurple, lightOrange, lightGray, white
}
