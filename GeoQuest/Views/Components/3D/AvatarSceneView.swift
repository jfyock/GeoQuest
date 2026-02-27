import SwiftUI
import RealityKit

/// A RealityKit-backed view that renders the player's 3D avatar using GLB assets.
///
/// Composition:
///   1. Loads `avatar_body_default.glb` via `GLBAssetLoader`.
///   2. Tints every model surface with the chosen body colour using
///      `PhysicallyBasedMaterial`.
///   3. Overlays the selected `avatar_acc_*.glb` accessory entity.
///   4. Positions a `PerspectiveCamera` entity so the avatar fills the frame.
///   5. Two `DirectionalLightComponent` entities (key + fill) for pleasant shading.
///
/// Uses `.id(bodyColor + accessory)` so SwiftUI only destroys/recreates the
/// `RealityView` when the 3D-relevant config changes; entities are served from
/// `GLBAssetLoader`'s cache so rebuilds are nearly instant (no disk I/O).
///
/// Renders nothing when GLB assets are absent — the parent `AvatarPreviewView`
/// shows the 2D fallback in that case.
struct AvatarSceneView: View {

    let config: AvatarConfig
    /// Continuously spins the avatar — enable on the customisation screen.
    var autoRotate: Bool = false
    /// Camera Z distance (larger = further away / more of the model visible).
    var cameraZ: Float = 2.5

    var body: some View {
        RealityView { content in
            await buildScene(in: &content)
        }
        // Rebuild only when body colour or accessory changes (eye/mouth/bg are 2D-only)
        .id(config.bodyColor.rawValue + config.accessory.rawValue)
    }

    // MARK: - Scene Construction

    private func buildScene(in content: inout RealityViewContent) async {
        // Camera
        let camEntity = Entity()
        var cam = PerspectiveCamera()
        cam.fieldOfViewInDegrees = 55
        camEntity.components.set(cam)
        camEntity.position = SIMD3<Float>(0, 0.3, cameraZ)
        camEntity.look(at: .zero, from: camEntity.position, relativeTo: nil)
        content.add(camEntity)

        // Key light
        let keyLight = Entity()
        var key = DirectionalLightComponent()
        key.intensity = 1200
        keyLight.components.set(key)
        keyLight.look(at: .zero, from: SIMD3<Float>(2, 4, 3), relativeTo: nil)
        content.add(keyLight)

        // Fill light
        let fillLight = Entity()
        var fill = DirectionalLightComponent()
        fill.intensity = 400
        fillLight.components.set(fill)
        fillLight.look(at: .zero, from: SIMD3<Float>(-3, 1, 2), relativeTo: nil)
        content.add(fillLight)

        // Body
        if let bodyEntity = await GLBAssetLoader.shared.entity(named: "avatar_body_default") {
            applyBodyColor(uiBodyColor(config.bodyColor), to: bodyEntity)
            if autoRotate { addSpin(to: bodyEntity) }
            content.add(bodyEntity)
        }

        // Accessory
        if let accName = accessoryModelName(config.accessory),
           let accEntity = await GLBAssetLoader.shared.entity(named: accName) {
            if autoRotate { addSpin(to: accEntity) }
            content.add(accEntity)
        }
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
