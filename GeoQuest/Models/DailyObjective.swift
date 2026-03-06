import Foundation

// MARK: - Objective Type

/// All possible daily objective categories. Used to route progress events.
enum DailyObjectiveType: String, Codable, CaseIterable {
    case completeAnyQuest
    case completeHardOrExpertQuest
    case createQuest
    case rateQuest
    case sendChatMessage
}

// MARK: - Objective Template (deterministic, date-seeded)

/// Immutable definition of a daily objective. Generated fresh each day from a
/// date-seeded pool — never stored in Firestore.
struct DailyObjectiveTemplate {
    let index: Int           // 0, 1, or 2 — position in today's 3-objective list
    let type: DailyObjectiveType
    let title: String
    let description: String
    let targetCount: Int
    let rewardPoints: Int
    let rewardGems: Int
    let difficulty: ObjectiveDifficulty

    enum ObjectiveDifficulty { case easy, medium, hard }
}

// MARK: - Live Objective (template + mutable progress)

struct DailyObjective: Identifiable {
    let template: DailyObjectiveTemplate
    var progress: Int
    var isClaimed: Bool

    var id: Int { template.index }
    var isComplete: Bool { progress >= template.targetCount }
}

// MARK: - Firestore Document (stored per user per day)

/// Only the mutable, per-user daily state is persisted. Templates are recomputed.
struct DailyStateDocument: Codable {
    /// ISO date string "YYYY-MM-DD" identifying which day this document covers.
    var dateKey: String
    /// Progress counter for each of the 3 objectives (index matches template index).
    var progress: [Int]
    /// Whether each objective's reward has been claimed.
    var claimed: [Bool]
    /// Whether the daily login bonus gems have been collected today.
    var loginBonusClaimed: Bool

    static func fresh(dateKey: String) -> DailyStateDocument {
        DailyStateDocument(
            dateKey: dateKey,
            progress: [0, 0, 0],
            claimed: [false, false, false],
            loginBonusClaimed: false
        )
    }
}

// MARK: - Objective Pool

/// The full pool of possible daily objective templates.
/// Each day, 3 are chosen deterministically using a date-seeded RNG so all
/// players face the same global challenges.
enum DailyObjectivePool {
    struct Entry {
        let type: DailyObjectiveType
        let title: String
        let description: String
        let targetCount: Int
        let rewardPoints: Int
        let rewardGems: Int
        let difficulty: DailyObjectiveTemplate.ObjectiveDifficulty
    }

    static let all: [Entry] = [
        // EASY — single-action objectives
        Entry(type: .completeAnyQuest,
              title: "Quest Starter",
              description: "Complete any quest today.",
              targetCount: 1, rewardPoints: 75, rewardGems: 8,
              difficulty: .easy),

        Entry(type: .sendChatMessage,
              title: "Say Something",
              description: "Send a message in global chat.",
              targetCount: 1, rewardPoints: 40, rewardGems: 5,
              difficulty: .easy),

        Entry(type: .rateQuest,
              title: "Quest Critic",
              description: "Rate a quest you've completed.",
              targetCount: 1, rewardPoints: 50, rewardGems: 6,
              difficulty: .easy),

        Entry(type: .createQuest,
              title: "Quest Maker",
              description: "Create and publish a quest.",
              targetCount: 1, rewardPoints: 100, rewardGems: 15,
              difficulty: .easy),

        Entry(type: .sendChatMessage,
              title: "Social Butterfly",
              description: "Drop 2 messages in global chat.",
              targetCount: 2, rewardPoints: 60, rewardGems: 7,
              difficulty: .easy),

        Entry(type: .rateQuest,
              title: "Reviewer",
              description: "Leave ratings on 2 quests.",
              targetCount: 2, rewardPoints: 80, rewardGems: 10,
              difficulty: .easy),

        // MEDIUM — multi-step or harder objectives
        Entry(type: .completeAnyQuest,
              title: "On a Roll",
              description: "Complete 2 quests today.",
              targetCount: 2, rewardPoints: 150, rewardGems: 18,
              difficulty: .medium),

        Entry(type: .completeAnyQuest,
              title: "Triple Threat",
              description: "Complete 3 quests in a single day.",
              targetCount: 3, rewardPoints: 225, rewardGems: 25,
              difficulty: .medium),

        Entry(type: .sendChatMessage,
              title: "Chatterbox",
              description: "Send 5 messages in global chat.",
              targetCount: 5, rewardPoints: 120, rewardGems: 14,
              difficulty: .medium),

        Entry(type: .rateQuest,
              title: "Quality Control",
              description: "Rate 3 different quests today.",
              targetCount: 3, rewardPoints: 130, rewardGems: 16,
              difficulty: .medium),

        Entry(type: .completeHardOrExpertQuest,
              title: "Rising to the Challenge",
              description: "Complete a hard or expert difficulty quest.",
              targetCount: 1, rewardPoints: 200, rewardGems: 22,
              difficulty: .medium),

        Entry(type: .createQuest,
              title: "Prolific Creator",
              description: "Publish 2 quests today.",
              targetCount: 2, rewardPoints: 180, rewardGems: 20,
              difficulty: .medium),

        // HARD — demanding objectives
        Entry(type: .completeAnyQuest,
              title: "Marathon Runner",
              description: "Complete 5 quests in a day. Pace yourself.",
              targetCount: 5, rewardPoints: 400, rewardGems: 45,
              difficulty: .hard),

        Entry(type: .completeHardOrExpertQuest,
              title: "Elite Explorer",
              description: "Complete 2 hard or expert quests today.",
              targetCount: 2, rewardPoints: 350, rewardGems: 40,
              difficulty: .hard),

        Entry(type: .rateQuest,
              title: "Hall Monitor",
              description: "Rate 5 quests. Help keep quality high.",
              targetCount: 5, rewardPoints: 250, rewardGems: 30,
              difficulty: .hard),

        Entry(type: .sendChatMessage,
              title: "Town Crier",
              description: "Send 10 messages in global chat.",
              targetCount: 10, rewardPoints: 200, rewardGems: 25,
              difficulty: .hard),

        Entry(type: .completeAnyQuest,
              title: "Quest Fanatic",
              description: "Complete 4 quests back to back.",
              targetCount: 4, rewardPoints: 320, rewardGems: 36,
              difficulty: .hard),

        Entry(type: .createQuest,
              title: "World Builder",
              description: "Create 3 new quests for other players.",
              targetCount: 3, rewardPoints: 300, rewardGems: 35,
              difficulty: .hard),
    ]

    /// Picks exactly 3 entries for today using a date-seeded RNG, ensuring
    /// one easy, one medium, and one hard objective per day.
    static func todaysObjectives() -> [DailyObjectiveTemplate] {
        let dateKey = Calendar.current.dateKey(for: Date())
        var rng = SeededRNG(seed: dateKey)

        let easy   = all.filter { $0.difficulty == .easy   }.shuffled(using: &rng)
        let medium = all.filter { $0.difficulty == .medium }.shuffled(using: &rng)
        let hard   = all.filter { $0.difficulty == .hard   }.shuffled(using: &rng)

        let entries = [easy[0], medium[0], hard[0]]
        return entries.enumerated().map { (idx, e) in
            DailyObjectiveTemplate(
                index: idx,
                type: e.type,
                title: e.title,
                description: e.description,
                targetCount: e.targetCount,
                rewardPoints: e.rewardPoints,
                rewardGems: e.rewardGems,
                difficulty: e.difficulty
            )
        }
    }
}

// MARK: - Seeded RNG

/// A simple xorshift64 generator. Given the same seed it always produces the
/// same sequence, so all players generate identical daily objectives.
private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed dateKey: String) {
        // Mix the date string bytes into a 64-bit seed
        var s: UInt64 = 0x9E3779B97F4A7C15
        for byte in dateKey.utf8 {
            s ^= UInt64(byte)
            s = s &* 6364136223846793005 &+ 1442695040888963407
        }
        self.state = s == 0 ? 1 : s
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

// MARK: - Calendar helper

extension Calendar {
    func dateKey(for date: Date) -> String {
        let comps = dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }

    func isYesterday(_ date: Date) -> Bool {
        guard let yesterday = self.date(byAdding: .day, value: -1, to: startOfDay(for: Date())) else { return false }
        return isDate(date, inSameDayAs: yesterday)
    }
}
