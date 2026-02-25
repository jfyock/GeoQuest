import SwiftUI
import MapKit

@Observable
final class MapViewModel {
    var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    var visibleQuests: [QuestAnnotationData] = []
    var selectedQuestId: String?
    var isLoadingQuests = false
    var showMenu = false

    private var lastLoadedRegion: MKCoordinateRegion?
    private let questService: QuestService

    init(questService: QuestService) {
        self.questService = questService
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

    func refreshQuests() async {
        lastLoadedRegion = nil
        if let center = lastLoadedRegion?.center {
            await loadQuestsForRegion(center: center)
        }
    }
}
