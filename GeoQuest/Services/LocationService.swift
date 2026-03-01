import CoreLocation
import MapKit

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    private(set) var currentLocation: CLLocationCoordinate2D?
    private(set) var currentCity: String = ""
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// Whether the player is currently moving (GPS speed above threshold).
    private(set) var isMoving: Bool = false
    /// The heading direction the player is moving in (radians, 0 = north, clockwise).
    private(set) var movementHeading: Float = 0
    /// Current speed in m/s from GPS.
    private(set) var currentSpeed: Double = 0

    /// Speed threshold (m/s) to consider the player "walking". ~0.5 m/s ≈ slow walk.
    private static let movementSpeedThreshold: Double = 0.5

    private var previousLocation: CLLocation?

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5 // finer updates for movement detection
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    func reverseGeocodeCurrentLocation() async {
        guard let location = currentLocation else { return }
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)

        if #available(iOS 26, *) {
            if let request = MKReverseGeocodingRequest(location: clLocation) {
                do {
                    let mapItems = try await request.mapItems
                    if let item = mapItems.first, let address = item.address {
                        currentCity = address.shortAddress ?? ""
                    }
                } catch {
                    // Silently fail - city is optional
                }
            }
        } else {
            do {
                let geocoder = CLGeocoder()
                let placemarks = try await geocoder.reverseGeocodeLocation(clLocation)
                if let city = placemarks.first?.locality {
                    currentCity = city
                }
            } catch {
                // Silently fail - city is optional
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            let oldLocation = self.previousLocation
            self.currentLocation = location.coordinate

            // Compute speed & heading from GPS
            let speed = location.speed >= 0 ? location.speed : 0
            self.currentSpeed = speed
            self.isMoving = speed >= Self.movementSpeedThreshold

            if let old = oldLocation, self.isMoving {
                let bearing = self.bearing(from: old.coordinate, to: location.coordinate)
                self.movementHeading = Float(bearing)
            } else if location.course >= 0 && self.isMoving {
                self.movementHeading = Float(location.course * .pi / 180)
            }

            self.previousLocation = location
        }
    }

    /// Calculates bearing in radians from one coordinate to another (0 = north, clockwise).
    private func bearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let dLon = (end.longitude - start.longitude) * .pi / 180

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        return atan2(y, x)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Location errors are non-fatal for the app
    }
}
