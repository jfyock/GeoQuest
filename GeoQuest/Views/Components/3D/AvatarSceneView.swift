import SwiftUI
import RealityKit

/// A RealityKit-backed view that renders the player's 3D avatar using GLB assets.
///
/// Composition:
///   1. Loads `avatar_body_default.glb` via `GLBAssetLoader`.
///   2. Tints every ModelEntity surface with the chosen body colour.
///   3. Overlays the selected `avatar_acc_*.glb` accessory entity.
///   4. Two directional lights (key + fill) for pleasant shading.
///   5. Auto-fits scale + position using visualBounds after entities are in the scene.
struct AvatarSceneView: View {

    let config: AvatarConfig
    var autoRotate: Bool = false
    var cameraZ: Float = 2.5

    var body: some View {
        RealityView { content in
            print("[AvatarSceneView] RealityView closure started — bodyColor=\(config.bodyColor) accessory=\(config.accessory)")

            // Key light (upper-right front)
            let keyLight = Entity()
            var key = DirectionalLightComponent()
            key.intensity = 1200
            keyLight.components.set(key)
            keyLight.look(at: .zero, from: SIMD3<Float>(2, 4, 3), relativeTo: nil)
            content.add(keyLight)

            // Fill light (upper-left back)
            let fillLight = Entity()
            var fill = DirectionalLightComponent()
            fill.intensity = 400
            fillLight.components.set(fill)
            fillLight.look(at: .zero, from: SIMD3<Float>(-3, 1, 2), relativeTo: nil)
            content.add(fillLight)

            // Root container — body + accessory scale as one unit
            let root = Entity()

            // Body
            if let bodyEntity = await GLBAssetLoader.shared.entity(named: "avatar_body_default") {
                print("[AvatarSceneView] ✅ body entity loaded")
                applyBodyColor(uiBodyColor(config.bodyColor), to: bodyEntity)
                root.addChild(bodyEntity)
            } else {
                print("[AvatarSceneView] ❌ body entity is nil — check GLBAssetLoader logs above")
            }

            // Accessory
            if let accName = accessoryModelName(config.accessory) {
                if let accEntity = await GLBAssetLoader.shared.entity(named: accName) {
                    print("[AvatarSceneView] ✅ accessory '\(accName)' loaded")
                    root.addChild(accEntity)
                } else {
                    print("[AvatarSceneView] ❌ accessory '\(accName)' is nil")
                }
            }

            if autoRotate { addSpin(to: root) }

            // Add to scene first — visualBounds requires scene membership to return
            // non-zero extents (the render pipeline must traverse the entity tree).
            content.add(root)

            // Auto-fit: scale and centre so the avatar fills the default camera view
            // regardless of the GLB's original unit scale (cm, m, etc.).
            let bounds = root.visualBounds(recursive: true, relativeTo: root, excludeInactive: false)
            let maxExtent = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
            print("[AvatarSceneView] root bounds — extents=\(bounds.extents) center=\(bounds.center)")
            if maxExtent > 0.0001 {
                let scale = Float(0.8) / maxExtent
                root.scale = SIMD3<Float>(repeating: scale)
                root.position = -bounds.center * scale
            }
        }
        // Rebuild only when body colour or accessory changes
        .id(config.bodyColor.rawValue + config.accessory.rawValue)
    }

    // MARK: - Helpers

    private func addSpin(to entity: Entity) {
        let spin = FromToByAnimation<Transform>(
            by: Transform(rotation: simd_quatf(angle: .pi * 2, axis: [0, 1, 0])),
            duration: 8,
            timing: .linear,
            isAdditive: true
        )
        if let resource = try? AnimationResource.generate(with: spin) {
            entity.playAnimation(resource.repeat())
        }
    }

    private func applyBodyColor(_ color: UIColor, to entity: Entity) {
        if let model = entity as? ModelEntity, var desc = model.model {
            desc.materials = desc.materials.map { _ in
                var mat = PhysicallyBasedMaterial()
                mat.baseColor = .init(tint: color)
                return mat
            }
            model.model = desc
        }
        for child in entity.children {
            applyBodyColor(color, to: child)
        }
    }

    private func accessoryModelName(_ accessory: AvatarAccessory) -> String? {
        switch accessory {
        case .none:        return nil
        case .hat:         return "avatar_acc_hat"
        case .crown:       return "avatar_acc_crown"
        case .glasses:     return "avatar_acc_glasses"
        case .sunglasses:  return "avatar_acc_sunglasses"
        case .headband:    return "avatar_acc_headband"
        case .antenna:     return "avatar_acc_antenna"
        case .bow:         return "avatar_acc_bow"
        }
    }

    private func uiBodyColor(_ color: AvatarBodyColor) -> UIColor {
        switch color {
        case .red:    return .systemRed
        case .orange: return .systemOrange
        case .yellow: return .systemYellow
        case .green:  return .systemGreen
        case .blue:   return .systemBlue
        case .indigo: return .systemIndigo
        case .purple: return .systemPurple
        case .pink:   return .systemPink
        case .teal:   return .systemTeal
        case .mint:   return UIColor(red: 0.0, green: 0.78, blue: 0.67, alpha: 1.0)
        case .cyan:   return .systemCyan
        case .brown:  return .systemBrown
        }
    }
}
