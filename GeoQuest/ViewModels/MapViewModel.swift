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
    /// Current map camera pitch in degrees (0 = top-down, 90 = horizon).
    var cameraPitch: Double = 0
    /// Currently playing emote on the player's avatar.
    var activeEmote: EmoteType?
    /// Whether the emote menu is showing.
    var showEmoteMenu = false
    /// Current map camera latitude delta for zoom-based scaling.
    var cameraSpanLatitudeDelta: Double = AppConstants.defaultMapSpanDelta
    /// Center coordinate of the current camera view.
    var cameraCenterCoordinate: CLLocationCoordinate2D?

    /// Atmospheric elements anchored to real map coordinates.
    var atmosphericElements: [AtmosphericElement] = []
    /// Tracks the last center used for atmospheric generation to avoid regenerating on small pans.
    private var lastAtmosphericCenter: CLLocationCoordinate2D?

    /// Scale factor for the player annotation based on current zoom level.
    var playerAnnotationScale: CGFloat {
        let normalizedZoom = AppConstants.defaultMapSpanDelta / max(cameraSpanLatitudeDelta, 0.0001)
        if normalizedZoom > 3.0 {
            return CGFloat(3.0 + log2(normalizedZoom / 3.0) * 0.5)
        }
        return CGFloat(max(normalizedZoom, 0.3))
    }

    private var lastLoadedRegion: MKCoordinateRegion?
    private let questService: QuestService
    private let questGenerationService: QuestGenerationService

    init(questService: QuestService, questGenerationService: QuestGenerationService) {
        self.questService = questService
        self.questGenerationService = questGenerationService
    }

    // MARK: - Atmospheric Element Generation

    /// Regenerates atmospheric elements around the given center coordinate.
    /// Uses MKLocalSearch to find airports and water bodies for contextual placement.
    func regenerateAtmosphericElements(center: CLLocationCoordinate2D) async {
        // Don't regenerate if we haven't moved much
        if let last = lastAtmosphericCenter,
           abs(last.latitude - center.latitude) < 0.01,
           abs(last.longitude - center.longitude) < 0.01 {
            return
        }
        lastAtmosphericCenter = center
        let span = cameraSpanLatitudeDelta

        var elements: [AtmosphericElement] = []

        // Search for airports and water bodies in parallel
        async let airportResults = searchMapItems(query: "airport", near: center, radiusMeters: 5000)
        async let waterResults = searchMapItems(query: "river lake ocean bay harbor marina port", near: center, radiusMeters: 3000)

        let airports = await airportResults
        let waterBodies = await waterResults

        // Birds — scattered around the area
        for i in 0..<6 {
            let coord = randomCoordinate(near: center, spanDelta: span * 0.6)
            elements.append(AtmosphericElement(
                id: "bird_\(i)",
                kind: .bird,
                coordinate: coord,
                heading: Double.random(in: 0..<360)
            ))
        }

        // Clouds — spread across a wider area
        for i in 0..<5 {
            let coord = randomCoordinate(near: center, spanDelta: span * 0.8)
            elements.append(AtmosphericElement(
                id: "cloud_\(i)",
                kind: .cloud,
                coordinate: coord,
                heading: Double.random(in: 240...300) // generally west-to-east drift
            ))
        }

        // Leaves — clustered near parks/green areas
        for i in 0..<4 {
            let coord = randomCoordinate(near: center, spanDelta: span * 0.4)
            elements.append(AtmosphericElement(
                id: "leaf_\(i)",
                kind: .leaf,
                coordinate: coord,
                heading: Double.random(in: 0..<360)
            ))
        }

        // Boats — only on or near water bodies
        for (i, waterItem) in waterBodies.prefix(4).enumerated() {
            let waterCoord: CLLocationCoordinate2D
            if #available(iOS 26, *) {
                waterCoord = waterItem.location.coordinate
            } else {
                waterCoord = waterItem.placemark.coordinate
            }
            let coord = randomCoordinate(near: waterCoord, spanDelta: span * 0.05)
            elements.append(AtmosphericElement(
                id: "boat_\(i)",
                kind: .boat,
                coordinate: coord,
                heading: Double.random(in: 0..<360)
            ))
        }
        // If no water found, add a couple of boats near rivers heuristically
        if waterBodies.isEmpty {
            for i in 0..<2 {
                let coord = randomCoordinate(near: center, spanDelta: span * 0.3)
                elements.append(AtmosphericElement(
                    id: "boat_fallback_\(i)",
                    kind: .boat,
                    coordinate: coord,
                    heading: Double.random(in: 0..<360)
                ))
            }
        }

        // Planes — take off from airports
        for (i, airport) in airports.prefix(3).enumerated() {
            let airportCoord: CLLocationCoordinate2D
            if #available(iOS 26, *) {
                airportCoord = airport.location.coordinate
            } else {
                airportCoord = airport.placemark.coordinate
            }
            elements.append(AtmosphericElement(
                id: "plane_\(i)",
                kind: .plane,
                coordinate: airportCoord,
                heading: Double.random(in: 0..<360)
            ))
        }
        // Always add at least one plane even without an airport
        if airports.isEmpty {
            let coord = randomCoordinate(near: center, spanDelta: span * 0.5)
            elements.append(AtmosphericElement(
                id: "plane_sky_0",
                kind: .plane,
                coordinate: coord,
                heading: Double.random(in: 0..<360)
            ))
        }

        // Hot air balloons
        for i in 0..<2 {
            let coord = randomCoordinate(near: center, spanDelta: span * 0.5)
            elements.append(AtmosphericElement(
                id: "balloon_\(i)",
                kind: .hotAirBalloon,
                coordinate: coord,
                heading: Double.random(in: 0..<360)
            ))
        }

        // Butterflies — small and near the player
        for i in 0..<3 {
            let coord = randomCoordinate(near: center, spanDelta: span * 0.2)
            elements.append(AtmosphericElement(
                id: "butterfly_\(i)",
                kind: .butterfly,
                coordinate: coord,
                heading: Double.random(in: 0..<360)
            ))
        }

        atmosphericElements = elements
    }

    private func searchMapItems(query: String, near center: CLLocationCoordinate2D, radiusMeters: Double) async -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: radiusMeters * 2,
            longitudinalMeters: radiusMeters * 2
        )
        request.resultTypes = .pointOfInterest
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            return response.mapItems
        } catch {
            return []
        }
    }

    private func randomCoordinate(near center: CLLocationCoordinate2D, spanDelta: Double) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: center.latitude + Double.random(in: -spanDelta...spanDelta),
            longitude: center.longitude + Double.random(in: -spanDelta...spanDelta)
        )
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

    /// Deactivates stale auto-generated quests and creates a fresh batch for the area.
    func forceRegenerate(near coordinate: CLLocationCoordinate2D) async {
        isLoadingQuests = true
        await questGenerationService.forceRegenerate(near: coordinate)
        lastLoadedRegion = nil
        await loadQuestsForRegion(center: coordinate)
        isLoadingQuests = false
    }
}
