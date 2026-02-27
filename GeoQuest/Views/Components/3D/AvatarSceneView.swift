import SwiftUI
import SceneKit
import ModelIO

/// A SceneKit-backed view that renders the player's 3D avatar from GLB assets.
///
/// Composition:
///   1. Loads `avatar_body_default.glb` via `GLBSceneLoader` (MDLAsset → SCNScene).
///   2. Tints every geometry's diffuse with the chosen body colour.
///   3. Overlays the selected `avatar_acc_*.glb` accessory node.
///   4. Auto-fits scale + position so the avatar is always framed by the fixed camera.
///
/// Why SceneKit instead of RealityKit:
///   ModelIO's MDLAsset.export(to: .usdc) strips mesh geometry — the resulting
///   Entity.load produces nodes with zero visual bounds.  SCNScene(mdlAsset:) is
///   the ModelIO-native conversion path and correctly preserves GLB geometry.
struct AvatarSceneView: View {

    let config: AvatarConfig
    var autoRotate: Bool = false
    var cameraZ: Float = 2.5

    var body: some View {
        _AvatarSCNView(config: config, autoRotate: autoRotate, cameraZ: cameraZ)
            .id(config.bodyColor.rawValue + config.accessory.rawValue)
    }
}

// MARK: - UIViewRepresentable

private struct _AvatarSCNView: UIViewRepresentable {

    let config: AvatarConfig
    let autoRotate: Bool
    let cameraZ: Float

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.isOpaque = false
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = false
        scnView.antialiasingMode = .multisampling4X

        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        // Fixed perspective camera — cameraZ from caller (default 2.5)
        let camNode = SCNNode()
        camNode.name = "avatarCamera"
        camNode.camera = SCNCamera()
        camNode.position = SCNVector3(0, 0, cameraZ)
        scene.rootNode.addChildNode(camNode)

        scnView.scene = scene
        scnView.pointOfView = camNode
        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        Task { @MainActor in
            await refreshAvatar(in: scnView)
        }
    }

    // MARK: - Avatar Loading

    @MainActor
    private func refreshAvatar(in scnView: SCNView) async {
        guard let scene = scnView.scene else { return }

        // Remove previous avatar (keep camera and lights)
        scene.rootNode.childNodes(passingTest: { n, _ in n.name == "avatarRoot" })
            .forEach { $0.removeFromParentNode() }

        let avatarRoot = SCNNode()
        avatarRoot.name = "avatarRoot"

        // Body
        if let bodyNode = await GLBSceneLoader.shared.node(named: "avatar_body_default") {
            print("[AvatarSceneView] ✅ body node loaded")
            applyBodyColor(uiBodyColor(config.bodyColor), to: bodyNode)
            avatarRoot.addChildNode(bodyNode)
        } else {
            print("[AvatarSceneView] ❌ body node is nil")
        }

        // Accessory
        if let accName = accessoryModelName(config.accessory) {
            if let accNode = await GLBSceneLoader.shared.node(named: accName) {
                print("[AvatarSceneView] ✅ accessory '\(accName)' loaded")
                avatarRoot.addChildNode(accNode)
            } else {
                print("[AvatarSceneView] ❌ accessory '\(accName)' is nil")
            }
        }

        // Auto-fit: SCNNode.boundingBox includes all child geometry and works on
        // detached nodes, so we can scale before adding to the scene.
        let (minBB, maxBB) = avatarRoot.boundingBox
        let sizeX = maxBB.x - minBB.x
        let sizeY = maxBB.y - minBB.y
        let sizeZ = maxBB.z - minBB.z
        let maxDim = max(sizeX, max(sizeY, sizeZ))
        print("[AvatarSceneView] avatarRoot boundingBox — min=\(minBB) max=\(maxBB)")
        if maxDim > 0.0001 {
            // Target 1.5 units: fills ~52% of the 60° FOV at cameraZ=2.5
            let s = Float(1.5) / maxDim
            avatarRoot.scale = SCNVector3(s, s, s)
            let cx = (minBB.x + maxBB.x) / 2
            let cy = (minBB.y + maxBB.y) / 2
            let cz = (minBB.z + maxBB.z) / 2
            avatarRoot.position = SCNVector3(-cx * s, -cy * s, -cz * s)
        }

        if autoRotate {
            avatarRoot.runAction(
                .repeatForever(.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 8))
            )
        }

        scene.rootNode.addChildNode(avatarRoot)
    }

    // MARK: - Helpers

    private func applyBodyColor(_ color: UIColor, to node: SCNNode) {
        if let geometry = node.geometry {
            for material in geometry.materials {
                material.diffuse.contents = color
            }
        }
        for child in node.childNodes {
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
