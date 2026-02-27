import CoreLocation
import MapKit

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    private(set) var currentLocation: CLLocationCoordinate2D?
    private(set) var currentCity: String = ""
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
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
        do {
            if #available(iOS 26, *) {
                let request = MKReverseGeocodingRequest(location: clLocation)
                let mapItems = try await request.mapItems
                if let item = mapItems.first, let address = item.address {
                    currentCity = address.shortAddress ?? ""
                }
            } else {
                let geocoder = CLGeocoder()
                let placemarks = try await geocoder.reverseGeocodeLocation(clLocation)
                if let city = placemarks.first?.locality {
                    currentCity = city
                }
            }
        } catch {
            // Silently fail - city is optional
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location.coordinate
        }
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
