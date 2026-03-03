import SwiftUI

@Observable
final class ProfileViewModel {
    var createdQuests: [Quest] = []
    var isLoadingQuests = false

    private let questService: QuestService

    init(questService: QuestService) {
        self.questService = questService
    }

    func loadCreatedQuests(userId: String) async {
        isLoadingQuests = true
        defer { isLoadingQuests = false }

        do {
            createdQuests = try await questService.fetchQuestsByCreator(userId: userId)
        } catch {
            // Silent fail
        }
    }
}
