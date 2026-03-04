import Foundation

enum EmoteType: String, CaseIterable, Codable, Identifiable, Sendable {
    case wave, dance, celebrate, clap, flex, spin, bow, shrug

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wave: return "Wave"
        case .dance: return "Dance"
        case .celebrate: return "Celebrate"
        case .clap: return "Clap"
        case .flex: return "Flex"
        case .spin: return "Spin"
        case .bow: return "Bow"
        case .shrug: return "Shrug"
        }
    }

    var iconName: String {
        switch self {
        case .wave: return "hand.wave.fill"
        case .dance: return "figure.dance"
        case .celebrate: return "party.popper.fill"
        case .clap: return "hands.clap.fill"
        case .flex: return "figure.strengthtraining.traditional"
        case .spin: return "arrow.triangle.2.circlepath"
        case .bow: return "figure.cooldown"
        case .shrug: return "person.crop.circle.badge.questionmark.fill"
        }
    }
}
