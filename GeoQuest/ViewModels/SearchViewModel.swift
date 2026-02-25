import SwiftUI
import CoreLocation

@Observable
final class SearchViewModel {
    var searchText = ""
    var results: [Quest] = []
    var isSearching = false
    var hasSearched = false

    private let questService: QuestService

    init(questService: QuestService) {
        self.questService = questService
    }

    func search() async {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            results = []
            hasSearched = false
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            results = try await questService.searchQuests(text: text)
            hasSearched = true
        } catch {
            results = []
            hasSearched = true
        }
    }

    func loadNearby(location: CLLocationCoordinate2D) async {
        isSearching = true
        defer { isSearching = false }

        do {
            results = try await questService.fetchQuestsInRegion(
                centerLat: location.latitude,
                centerLon: location.longitude
            )
            hasSearched = true
        } catch {
            results = []
            hasSearched = true
        }
    }

    func clear() {
        searchText = ""
        results = []
        hasSearched = false
    }
}
