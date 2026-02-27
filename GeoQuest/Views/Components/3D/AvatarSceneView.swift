import SwiftUI
import SceneKit

/// A SceneKit-backed view that renders the player's 3D avatar using GLB assets.
///
/// Composition:
///   1. Loads `avatar_body_default.glb` as the base mesh.
///   2. Applies the chosen body colour as the diffuse material on every geometry surface.
///   3. Overlays the selected accessory GLB node on top of the body.
///   4. Uses a soft two-light rig (ambient + directional) so the model reads well
///      against any background colour.
///
/// The view has a transparent background, letting the parent's SwiftUI background
/// (e.g. the coloured circle in `AvatarPreviewView`) show through.
///
/// When GLB assets are not yet present in the bundle the view renders nothing —
/// the parent is responsible for showing the 2D fallback.
struct AvatarSceneView: UIViewRepresentable {

    let config: AvatarConfig
    /// Continuously spins the avatar — enable on the customisation screen.
    var autoRotate: Bool = false
    /// Z-axis camera distance (tweak per context: larger = further away).
    var cameraZ: Float = 2.5

    // MARK: - Coordinator

    final class Coordinator {
        var lastConfig: AvatarConfig?
        var lastAutoRotate: Bool?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.isOpaque = false
        scnView.antialiasingMode = .multisampling4X
        scnView.autoenablesDefaultLighting = false
        scnView.allowsCameraControl = false
        scnView.rendersContinuously = autoRotate

        let scene = buildScene(autoRotate: autoRotate)
        scnView.scene = scene
        scnView.pointOfView = scene.rootNode.childNode(withName: "camera", recursively: false)

        context.coordinator.lastConfig = config
        context.coordinator.lastAutoRotate = autoRotate
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        let configChanged = context.coordinator.lastConfig != config
        let rotateChanged = context.coordinator.lastAutoRotate != autoRotate
        guard configChanged || rotateChanged else { return }

        context.coordinator.lastConfig = config
        context.coordinator.lastAutoRotate = autoRotate

        let scene = buildScene(autoRotate: autoRotate)
        uiView.scene = scene
        uiView.pointOfView = scene.rootNode.childNode(withName: "camera", recursively: false)
        uiView.rendersContinuously = autoRotate
    }

    // MARK: - Scene Construction

    private func buildScene(autoRotate: Bool) -> SCNScene {
        let scene = SCNScene()

        // Body
        if let bodyNode = GLBAssetLoader.shared.clonedRootNode(named: "avatar_body_default") {
            applyBodyColor(uiBodyColor(config.bodyColor), to: bodyNode)
            bodyNode.name = "body"

            if autoRotate {
                let spin = SCNAction.repeatForever(
                    .rotateBy(x: 0, y: .pi * 2, z: 0, duration: 8)
                )
                bodyNode.runAction(spin)
            }

            scene.rootNode.addChildNode(bodyNode)
        }

        // Accessory
        if let accName = accessoryModelName(config.accessory),
           let accNode = GLBAssetLoader.shared.clonedRootNode(named: accName) {
            accNode.name = "accessory"
            if autoRotate {
                // Inherit the same spin action so accessory moves with body
                let spin = SCNAction.repeatForever(
                    .rotateBy(x: 0, y: .pi * 2, z: 0, duration: 8)
                )
                accNode.runAction(spin)
            }
            scene.rootNode.addChildNode(accNode)
        }

        // Lighting
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 450
        ambient.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.intensity = 900
        key.light?.color = UIColor.white
        key.position = SCNVector3(2, 4, 3)
        key.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(key)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .directional
        fill.light?.intensity = 350
        fill.light?.color = UIColor.white
        fill.position = SCNVector3(-3, 1, 2)
        fill.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(fill)

        // Camera
        let cameraNode = SCNNode()
        cameraNode.name = "camera"
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 55
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 100
        cameraNode.position = SCNVector3(0, 0.3, Double(cameraZ))
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)

        return scene
    }

    // MARK: - Helpers

    private func applyBodyColor(_ color: UIColor, to node: SCNNode) {
        node.enumerateHierarchy { n, _ in
            guard let geo = n.geometry else { return }
            geo.materials.forEach { mat in
                mat.diffuse.contents = color
                mat.lightingModel = .phong
                mat.specular.contents = UIColor.white.withAlphaComponent(0.3)
                mat.shininess = 0.5
            }
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
