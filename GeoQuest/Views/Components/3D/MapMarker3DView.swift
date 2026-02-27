import SwiftUI
import RealityKit

/// A 3D model view for a single map annotation pin.
///
/// Uses `RealityView` to render a GLB asset. This is intentionally limited to
/// **one instance at a time** on screen (the player marker). Quest pins use the
/// 2D path in `QuestAnnotationView` to avoid GPU exhaustion from multiple
/// concurrent Metal render contexts.
struct MapMarker3DView: View {

    let modelName: String

    var body: some View {
        RealityView { content in
            if let entity = await GLBAssetLoader.shared.entity(named: modelName) {
                content.add(entity)
            }
        }
    }
}
