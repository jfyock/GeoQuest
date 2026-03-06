import SwiftUI
import CoreLocation
import PhotosUI

@Observable
final class QuestCreationViewModel {
    enum CreationState {
        case editing
        case submitting
        case success(String) // quest ID
        case error(String)
    }

    var state: CreationState = .editing
    var title = ""
    var description = ""
    var selectedLocation: CLLocationCoordinate2D?
    var useCurrentLocation = true
    var steps: [QuestStep] = [QuestStep(orderIndex: 0, instruction: "")]
    var secretCode = ""
    var selectedIcon = "mappin.circle.fill"
    var selectedColor = "FF6B35"
    var difficulty: QuestDifficulty = .medium

    // Image attachment
    var selectedPhotoItem: PhotosPickerItem?
    var questImage: UIImage?
    var isLoadingImage = false

    private let questService: QuestService
    private let userService: UserService
    private let leaderboardService: LeaderboardService
    private let storageService = StorageService()

    init(questService: QuestService, userService: UserService, leaderboardService: LeaderboardService) {
        self.questService = questService
        self.userService = userService
        self.leaderboardService = leaderboardService
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && !description.trimmingCharacters(in: .whitespaces).isEmpty
            && secretCode.isValidSecretCode
            && steps.allSatisfy { !$0.instruction.trimmingCharacters(in: .whitespaces).isEmpty }
            && steps.count >= AppConstants.minQuestSteps
    }

    var estimatedPoints: Int {
        ScoreCalculator.baseQuestValue(stepCount: steps.count)
    }

    func addStep() {
        guard steps.count < AppConstants.maxQuestSteps else { return }
        let newStep = QuestStep(orderIndex: steps.count, instruction: "")
        withAnimation(GQTheme.bouncy) {
            steps.append(newStep)
        }
    }

    func removeStep(at index: Int) {
        guard steps.count > AppConstants.minQuestSteps else { return }
        withAnimation(GQTheme.bouncy) {
            steps.remove(at: index)
            // Re-index
            for i in steps.indices {
                steps[i].orderIndex = i
            }
        }
    }

    func moveStep(from source: IndexSet, to destination: Int) {
        steps.move(fromOffsets: source, toOffset: destination)
        for i in steps.indices {
            steps[i].orderIndex = i
        }
    }

    func loadSelectedPhoto() async {
        guard let item = selectedPhotoItem else { return }
        isLoadingImage = true
        defer { isLoadingImage = false }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            questImage = image
        }
    }

    func removeImage() {
        questImage = nil
        selectedPhotoItem = nil
    }

    func createQuest(userId: String, displayName: String, currentLocation: CLLocationCoordinate2D?) async {
        let location = useCurrentLocation ? currentLocation : selectedLocation
        guard let location else {
            state = .error("No location selected. Please enable location services or pick a location.")
            return
        }
        guard isValid else {
            state = .error("Please fill in all required fields.")
            return
        }

        state = .submitting
        do {
            let quest = Quest(
                creatorId: userId,
                creatorDisplayName: displayName,
                title: title.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces),
                latitude: location.latitude,
                longitude: location.longitude,
                steps: steps,
                secretCode: secretCode,
                iconName: selectedIcon,
                iconColor: selectedColor,
                difficulty: difficulty
            )

            let questId = try await questService.createQuest(quest)

            // Upload cover image if one was selected
            if let image = questImage,
               let jpegData = image.jpegData(compressionQuality: 0.8) {
                let path = "quests/\(questId)/cover.jpeg"
                let url = try await storageService.uploadImage(data: jpegData, path: path)
                try await questService.updateImageURL(questId: questId, imageURL: url.absoluteString)
            }

            try await userService.incrementQuestsCreated(userId: userId)
            try await userService.updateScore(userId: userId, additionalPoints: ScoreCalculator.questCreationPoints)

            state = .success(questId)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func reset() {
        state = .editing
        title = ""
        description = ""
        selectedLocation = nil
        useCurrentLocation = true
        steps = [QuestStep(orderIndex: 0, instruction: "")]
        secretCode = ""
        selectedIcon = "mappin.circle.fill"
        selectedColor = "FF6B35"
        difficulty = .medium
        questImage = nil
        selectedPhotoItem = nil
    }
}
