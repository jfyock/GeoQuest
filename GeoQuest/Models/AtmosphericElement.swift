import CoreLocation

/// A world-anchored atmospheric element placed at a real map coordinate.
/// These elements are rendered as map annotations and move with the map.
struct AtmosphericElement: Identifiable {
    let id: String
    let kind: Kind
    let coordinate: CLLocationCoordinate2D
    /// Direction of travel in degrees (0 = north, clockwise).
    let heading: Double

    enum Kind: String {
        case bird
        case boat
        case cloud
        case leaf
        case plane
        case hotAirBalloon
        case butterfly
    }
}
