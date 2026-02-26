import CoreLocation
import MapKit

final class QuestGenerationService {
    private let questService: QuestService

    /// Tracks geohashes we've already attempted generation for this session,
    /// preventing redundant searches on repeated map loads.
    private var attemptedGeoHashes: Set<String> = []

    init(questService: QuestService) {
        self.questService = questService
    }

    // MARK: - Public API

    /// Generates quests near the coordinate if the area is sparse.
    /// Safe to call multiple times — skips if already attempted for this geohash.
    func generateQuestsIfNeeded(near coordinate: CLLocationCoordinate2D) async {
        let geoHash = GeoHash.encode(latitude: coordinate.latitude, longitude: coordinate.longitude)

        guard !attemptedGeoHashes.contains(geoHash) else { return }
        attemptedGeoHashes.insert(geoHash)

        do {
            let existingQuests = try await questService.fetchQuestsInRegion(
                centerLat: coordinate.latitude,
                centerLon: coordinate.longitude
            )

            let activeCount = existingQuests.filter { $0.isActive }.count
            guard activeCount < AppConstants.Generation.maxQuestsPerRegion else { return }

            let slotsAvailable = AppConstants.Generation.maxQuestsPerRegion - activeCount
            let questsToGenerate = min(
                Int.random(in: AppConstants.Generation.batchSizeRange),
                slotsAvailable
            )
            guard questsToGenerate > 0 else { return }

            // Fetch real-world map data
            let nearbyPlaces = await searchNearbyPlaces(near: coordinate)
            guard nearbyPlaces.count >= 2 else { return }

            let streetInfo = await reverseGeocode(coordinate: coordinate)

            // Generate and save each quest
            for _ in 0..<questsToGenerate {
                let shuffledPlaces = nearbyPlaces.shuffled()
                let placeCount = min(shuffledPlaces.count, Int.random(in: 2...4))
                let questPlaces = Array(shuffledPlaces.prefix(placeCount))

                // Place quest near the first POI so players start nearby
                let questCoord = randomOffset(
                    from: questPlaces[0].placemark.coordinate,
                    metersRange: 30...120
                )

                let quest = buildQuest(
                    near: questCoord,
                    places: questPlaces,
                    streetInfo: streetInfo
                )
                _ = try await questService.createQuest(quest)
            }
        } catch {
            // Quest generation is non-critical — never block the player experience
            print("[GeoQuest] Quest generation failed: \(error)")
        }
    }

    // MARK: - Map Data Fetching

    private func searchNearbyPlaces(near coordinate: CLLocationCoordinate2D) async -> [MKMapItem] {
        // Try two different search queries for variety, stop once we have enough
        let queries = ["restaurant cafe", "store shop park"].shuffled()

        for query in queries {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: AppConstants.Generation.poiSearchRadiusMeters * 2,
                longitudinalMeters: AppConstants.Generation.poiSearchRadiusMeters * 2
            )
            request.resultTypes = .pointOfInterest

            do {
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                let items = response.mapItems.filter { $0.name != nil }
                if items.count >= 2 {
                    return Array(items.prefix(20))
                }
            } catch {
                continue
            }
        }
        return []
    }

    private struct StreetInfo {
        let streetName: String?
        let neighborhood: String?
        let city: String?
        let subThoroughfare: String?
    }

    private func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> StreetInfo {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let pm = placemarks.first else {
                return StreetInfo(streetName: nil, neighborhood: nil, city: nil, subThoroughfare: nil)
            }
            return StreetInfo(
                streetName: pm.thoroughfare,
                neighborhood: pm.subLocality ?? pm.locality,
                city: pm.locality,
                subThoroughfare: pm.subThoroughfare
            )
        } catch {
            return StreetInfo(streetName: nil, neighborhood: nil, city: nil, subThoroughfare: nil)
        }
    }

    // MARK: - Quest Building

    private func buildQuest(
        near coordinate: CLLocationCoordinate2D,
        places: [MKMapItem],
        streetInfo: StreetInfo
    ) -> Quest {
        let primaryPlace = places[0]
        let primaryName = primaryPlace.name ?? "the landmark"
        let streetName = primaryPlace.placemark.thoroughfare
            ?? streetInfo.streetName
            ?? "the main road"
        let area = streetInfo.neighborhood ?? streetInfo.city ?? "the area"

        let title = fillTemplate(
            QuestGenerationData.questTitleTemplates.randomElement()!,
            place: primaryName, street: streetName, area: area
        )

        let description = fillTemplate(
            QuestGenerationData.questDescriptionTemplates.randomElement()!,
            place: primaryName, street: streetName, area: area
        )

        let steps = generateSteps(places: places, streetInfo: streetInfo)
        let secretCode = generateSecretCode(from: places)
        let difficulty = weightedRandomDifficulty()

        // Spread creation dates across the past few weeks for a natural feel
        let daysAgo = Int.random(in: 1...21)
        let hoursAgo = Int.random(in: 0...23)
        var createdDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        createdDate = Calendar.current.date(byAdding: .hour, value: -hoursAgo, to: createdDate) ?? createdDate

        var quest = Quest(
            creatorId: AppConstants.Generation.creatorIdPrefix + UUID().uuidString,
            creatorDisplayName: QuestGenerationData.fakeUsernames.randomElement()!,
            title: String(title.prefix(AppConstants.maxQuestTitleCharacters)),
            description: String(description.prefix(AppConstants.maxQuestDescriptionCharacters)),
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            steps: steps,
            secretCode: secretCode,
            iconName: QuestGenerationData.questIcons.randomElement()!,
            iconColor: QuestGenerationData.questColors.randomElement()!,
            difficulty: difficulty
        )
        quest.createdAt = createdDate

        return quest
    }

    // MARK: - Step Generation

    private func generateSteps(places: [MKMapItem], streetInfo: StreetInfo) -> [QuestStep] {
        var steps: [QuestStep] = []
        let area = streetInfo.neighborhood ?? streetInfo.city ?? "the area"
        var orderIndex = 0

        // First step — orient the player
        if let first = places.first {
            let name = first.name ?? "the landmark"
            let street = first.placemark.thoroughfare ?? streetInfo.streetName ?? "the road"
            let instruction = fillTemplate(
                QuestGenerationData.firstStepTemplates.randomElement()!,
                place: name, street: street, area: area
            )
            steps.append(QuestStep(orderIndex: orderIndex, instruction: instruction))
            orderIndex += 1
        }

        // Middle steps — navigate between POIs
        if places.count > 2 {
            for i in 1..<(places.count - 1) {
                let place = places[i]
                let name = place.name ?? "the next spot"
                let street = place.placemark.thoroughfare ?? streetInfo.streetName ?? "the street"
                let direction = QuestGenerationData.directions.randomElement()!
                let side = QuestGenerationData.sides.randomElement()!

                let template = QuestGenerationData.middleStepTemplates.randomElement()!
                var instruction = fillTemplate(template, place: name, street: street, area: area)
                instruction = instruction
                    .replacingOccurrences(of: "{direction}", with: direction)
                    .replacingOccurrences(of: "{side}", with: side)
                steps.append(QuestStep(orderIndex: orderIndex, instruction: instruction))
                orderIndex += 1
            }
        }

        // Optional observation step for 2-place quests to add depth
        if places.count == 2, Bool.random() {
            let street = streetInfo.streetName ?? places[0].placemark.thoroughfare ?? "the street"
            let instruction = fillTemplate(
                QuestGenerationData.observationStepTemplates.randomElement()!,
                place: "", street: street, area: area
            )
            steps.append(QuestStep(orderIndex: orderIndex, instruction: instruction))
            orderIndex += 1
        }

        // Final step — find the code
        if let last = places.last, places.count > 1 {
            let name = last.name ?? "your destination"
            let street = last.placemark.thoroughfare ?? streetInfo.streetName ?? "the street"
            let addressNumber = last.placemark.subThoroughfare

            let instruction: String
            if addressNumber != nil {
                // Code is the address number — use address-based template
                instruction = fillTemplate(
                    QuestGenerationData.finalStepTemplates.randomElement()!,
                    place: name, street: street, area: area
                )
            } else if let placeName = last.name, extractNameCode(from: placeName) != nil {
                // Code is from place name — use name-based template
                let codeLength = min(6, placeName.filter { $0.isLetter }.count)
                var tmpl = QuestGenerationData.nameBasedFinalStepTemplates.randomElement()!
                tmpl = tmpl.replacingOccurrences(of: "{n}", with: "\(codeLength)")
                instruction = fillTemplate(tmpl, place: name, street: street, area: area)
            } else {
                instruction = fillTemplate(
                    QuestGenerationData.finalStepTemplates.randomElement()!,
                    place: name, street: street, area: area
                )
            }
            steps.append(QuestStep(orderIndex: orderIndex, instruction: instruction))
        }

        return steps
    }

    // MARK: - Secret Code Generation

    private func generateSecretCode(from places: [MKMapItem]) -> String {
        // Strategy 1: Use address number from the final place
        if let last = places.last,
           let address = last.placemark.subThoroughfare,
           address.count >= AppConstants.minSecretCodeLength {
            return String(address.prefix(AppConstants.maxSecretCodeLength))
        }

        // Strategy 2: Use first letters of the last place's name
        if let last = places.last, let code = extractNameCode(from: last.name ?? "") {
            return code
        }

        // Strategy 3: Combine initials from multiple places
        let initials = places
            .compactMap { $0.name?.first }
            .map { String($0).uppercased() }
            .joined()
        if initials.count >= AppConstants.minSecretCodeLength {
            return String(initials.prefix(AppConstants.maxSecretCodeLength))
        }

        // Fallback: Generate a pronounceable random code
        return randomCode(length: 6)
    }

    private func extractNameCode(from name: String) -> String? {
        let letters = name.uppercased().filter { $0.isLetter }
        guard letters.count >= AppConstants.minSecretCodeLength else { return nil }
        return String(letters.prefix(6))
    }

    private func randomCode(length: Int) -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<length).map { _ in chars.randomElement()! })
    }

    // MARK: - Difficulty Weighting

    private func weightedRandomDifficulty() -> QuestDifficulty {
        let roll = Int.random(in: 1...100)
        switch roll {
        case 1...35: return .easy
        case 36...65: return .medium
        case 66...85: return .hard
        default: return .expert
        }
    }

    // MARK: - Geo Utilities

    private func randomOffset(
        from coordinate: CLLocationCoordinate2D,
        metersRange: ClosedRange<Double>
    ) -> CLLocationCoordinate2D {
        let distance = Double.random(in: metersRange)
        let bearing = Double.random(in: 0..<360) * .pi / 180

        let lat1 = coordinate.latitude * .pi / 180
        let lon1 = coordinate.longitude * .pi / 180
        let earthRadius = 6_371_000.0

        let angDist = distance / earthRadius

        let lat2 = asin(
            sin(lat1) * cos(angDist) + cos(lat1) * sin(angDist) * cos(bearing)
        )
        let lon2 = lon1 + atan2(
            sin(bearing) * sin(angDist) * cos(lat1),
            cos(angDist) - sin(lat1) * sin(lat2)
        )

        return CLLocationCoordinate2D(
            latitude: lat2 * 180 / .pi,
            longitude: lon2 * 180 / .pi
        )
    }

    // MARK: - Template Helpers

    private func fillTemplate(_ template: String, place: String, street: String, area: String) -> String {
        template
            .replacingOccurrences(of: "{place}", with: place)
            .replacingOccurrences(of: "{street}", with: street)
            .replacingOccurrences(of: "{area}", with: area)
    }
}
