import SwiftUI
import MapKit

enum MapStyleConfiguration {
    static var cartoonStyle: MapStyle {
        .standard(
            elevation: .flat,
            emphasis: .muted,
            pointsOfInterest: .excludingAll,
            showsTraffic: false
        )
    }
}
