import Foundation

enum ScoreCalculator {
    // Points awarded for creating a quest
    static let questCreationPoints = 50

    // Points the creator earns each time someone completes their quest
    static let creatorCompletionBonus = 10

    // Base point value for completing a quest (function of step count)
    static func baseQuestValue(stepCount: Int) -> Int {
        100 + (stepCount * 10)
    }

    // Total points a player earns for completing a quest
    static func completionPoints(quest: Quest) -> Int {
        var points = quest.pointValue

        // Quality quest bonus: high rating with enough reviews
        if quest.averageRating >= 4.5 && quest.totalRatings >= 5 {
            points += 50
        }

        // Popular quest bonus
        if quest.totalCompletions >= 100 {
            points += 50
        } else if quest.totalCompletions >= 25 {
            points += 25
        }

        // Difficulty multiplier
        switch quest.difficulty {
        case .easy:
            break
        case .medium:
            points = Int(Double(points) * 1.25)
        case .hard:
            points = Int(Double(points) * 1.5)
        case .expert:
            points = Int(Double(points) * 2.0)
        }

        return points
    }
}
