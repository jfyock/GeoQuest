import SwiftUI
import RealityKit

/// A lightweight 3D model view for map annotation pins.
///
/// Uses `Model3D` instead of `RealityView` — `Model3D` shares a single GPU render
/// context across all instances on screen, so having 10-15 quest pins simultaneously
/// visible doesn't exhaust Metal allocations the way individual `RealityView` instances
/// would.  `RealityView` is reserved for the single full-featured avatar on the
/// customisation screen.
///
/// The GLB model's own baked-in materials are displayed as designed (tree, chest,
/// flag, etc. each have their natural colours). The difficulty dot and completion
/// badge continue to be drawn as SwiftUI overlays in `QuestAnnotationView`.
struct MapMarker3DView: View {

    let modelName: String

    var body: some View {
        if let url = Bundle.main.url(forResource: modelName, withExtension: "glb") {
            Model3D(url: url) { model in
                model
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                EmptyView()
            }
        }
    }
}
