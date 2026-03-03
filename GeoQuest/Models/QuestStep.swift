import Foundation

struct QuestStep: Codable, Identifiable, Sendable, Equatable {
    var id: String
    var orderIndex: Int
    var instruction: String

    init(id: String = UUID().uuidString, orderIndex: Int, instruction: String) {
        self.id = id
        self.orderIndex = orderIndex
        self.instruction = instruction.truncated(to: AppConstants.maxStepCharacters)
    }
}
