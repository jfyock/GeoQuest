import SwiftUI
import RealityKit

/// A lightweight, statically-rendered RealityKit view for map annotation pins.
///
/// Renders a single GLB model with an optional colour tint applied to all surfaces.
/// The `make` closure only runs once per annotation instance (entity and model name
/// are constant), so rendering cost is comparable to the previous 2D approach.
///
/// Difficulty-to-model mapping used by `QuestAnnotationView`:
///   .easy   → map_object_tree.glb   (falling back to map_marker_quest.glb)
///   .medium → map_marker_quest.glb
///   .hard   → map_object_chest.glb  (falling back to map_marker_quest.glb)
///   .expert → map_object_flag.glb   (falling back to map_marker_quest.glb)
struct MapMarker3DView: View {

    let modelName: String
    /// Optional tint applied to every surface (e.g. difficulty colour).
    var tintColor: UIColor? = nil
    /// Camera Y height — raise for top-down, lower for side-on.
    var cameraY: Float = 1.2
    /// Camera Z distance.
    var cameraZ: Float = 2.0

    var body: some View {
        RealityView { content in
            // Camera
            let camEntity = Entity()
            var cam = PerspectiveCamera()
            cam.fieldOfViewInDegrees = 60
            camEntity.components.set(cam)
            let camPos = SIMD3<Float>(0, cameraY, cameraZ)
            camEntity.position = camPos
            camEntity.look(at: .zero, from: camPos, relativeTo: nil)
            content.add(camEntity)

            // Lighting
            let lightEntity = Entity()
            var light = DirectionalLightComponent()
            light.intensity = 1200
            lightEntity.components.set(light)
            lightEntity.look(at: .zero, from: SIMD3<Float>(1, 3, 2), relativeTo: nil)
            content.add(lightEntity)

            // Model
            if let modelEntity = await GLBAssetLoader.shared.entity(named: modelName) {
                if let color = tintColor {
                    applyTint(color, to: modelEntity)
                }
                content.add(modelEntity)
            }
        }
    }

    // MARK: - Helpers

    private func applyTint(_ color: UIColor, to entity: Entity) {
        if let model = entity as? ModelEntity, var desc = model.model {
            desc.materials = desc.materials.map { _ in
                var mat = PhysicallyBasedMaterial()
                mat.baseColor = .init(tint: color)
                return mat
            }
            model.model = desc
        }
        for child in entity.children {
            applyTint(color, to: child)
        }
    }
}
