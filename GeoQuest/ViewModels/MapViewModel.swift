import SwiftUI
import MapKit

@Observable
final class MapViewModel {
    var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    var visibleQuests: [QuestAnnotationData] = []
    var selectedQuestId: String?
    var isLoadingQuests = false
    var showMenu = false
    /// Current map camera heading in degrees (0 = north, clockwise).
    var cameraHeading: Double = 0

    private var lastLoadedRegion: MKCoordinateRegion?
    private let questService: QuestService
    private let questGenerationService: QuestGenerationService

    init(questService: QuestService, questGenerationService: QuestGenerationService) {
        self.questService = questService
        self.questGenerationService = questGenerationService
    }

    func loadQuestsForRegion(center: CLLocationCoordinate2D) async {
        // Avoid reloading if we haven't moved much
        if let last = lastLoadedRegion,
           abs(last.center.latitude - center.latitude) < 0.005,
           abs(last.center.longitude - center.longitude) < 0.005 {
            return
        }

        isLoadingQuests = true
        defer { isLoadingQuests = false }

        do {
            let quests = try await questService.fetchQuestsInRegion(
                centerLat: center.latitude,
                centerLon: center.longitude
            )
            visibleQuests = quests.map { QuestAnnotationData(from: $0) }
            lastLoadedRegion = MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(
                    latitudeDelta: AppConstants.defaultMapSpanDelta,
                    longitudeDelta: AppConstants.defaultMapSpanDelta
                )
            )
        } catch {
            // Silently fail - quests will load on next pan
        }
    }

    func markQuestCompleted(questId: String) {
        if let index = visibleQuests.firstIndex(where: { $0.id == questId }) {
            let old = visibleQuests[index]
            visibleQuests[index] = QuestAnnotationData(
                from: Quest(
                    id: old.id,
                    creatorId: "",
                    creatorDisplayName: "",
                    title: old.title,
                    description: "",
                    latitude: old.coordinate.latitude,
                    longitude: old.coordinate.longitude,
                    steps: [],
                    secretCode: "",
                    iconName: old.iconName,
                    iconColor: old.iconColor.hexString,
                    difficulty: old.difficulty
                ),
                isCompleted: true
            )
        }
    }

    /// Generates quests if the area is sparse, then reloads to display them.
    /// Called once on initial map load (i.e. on login).
    func generateQuestsIfNeeded(near coordinate: CLLocationCoordinate2D) async {
        await questGenerationService.generateQuestsIfNeeded(near: coordinate)
        // Force reload to pick up any newly generated quests
        lastLoadedRegion = nil
        await loadQuestsForRegion(center: coordinate)
    }

    func refreshQuests() async {
        lastLoadedRegion = nil
        if let center = lastLoadedRegion?.center {
            await loadQuestsForRegion(center: center)
        }
    }
}
