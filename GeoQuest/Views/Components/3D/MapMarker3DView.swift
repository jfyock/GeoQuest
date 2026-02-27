import SwiftUI
import SceneKit

/// A lightweight, statically-rendered SceneKit view used for map annotations.
///
/// Renders a single GLB model with an optional colour tint applied to all surfaces.
/// `rendersContinuously` is off by default — the scene is drawn once and cached as a
/// Metal texture, keeping map scroll performance smooth even with many annotations.
///
/// Difficulty-to-model mapping used by `QuestAnnotationView`:
///   .easy   → map_object_tree.glb   (falling back to map_marker_quest.glb)
///   .medium → map_marker_quest.glb
///   .hard   → map_object_chest.glb  (falling back to map_marker_quest.glb)
///   .expert → map_object_flag.glb   (falling back to map_marker_quest.glb)
struct MapMarker3DView: UIViewRepresentable {

    let modelName: String
    /// Optional tint applied to every diffuse surface (e.g. difficulty colour).
    var tintColor: UIColor? = nil
    /// Camera Y height — raise for top-down, lower for side-on.
    var cameraY: Float = 1.2
    /// Camera Z distance.
    var cameraZ: Float = 2.0

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.isOpaque = false
        scnView.antialiasingMode = .multisampling2X
        scnView.autoenablesDefaultLighting = false
        scnView.allowsCameraControl = false
        scnView.rendersContinuously = false

        scnView.scene = buildScene()
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // Model name / tint are constant per annotation instance; no rebuild needed.
    }

    // MARK: - Scene Construction

    private func buildScene() -> SCNScene {
        let scene = SCNScene()

        if let modelNode = GLBAssetLoader.shared.clonedRootNode(named: modelName) {
            if let color = tintColor {
                applyTint(color, to: modelNode)
            }
            scene.rootNode.addChildNode(modelNode)
        }

        // Lighting
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 600
        ambient.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambient)

        let directional = SCNNode()
        directional.light = SCNLight()
        directional.light?.type = .directional
        directional.light?.intensity = 800
        directional.light?.color = UIColor.white
        directional.position = SCNVector3(1, 3, 2)
        directional.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(directional)

        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 60
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 50
        cameraNode.position = SCNVector3(0, Double(cameraY), Double(cameraZ))
        cameraNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(cameraNode)

        return scene
    }

    private func applyTint(_ color: UIColor, to node: SCNNode) {
        node.enumerateHierarchy { n, _ in
            n.geometry?.materials.forEach { mat in
                mat.diffuse.contents = color
                mat.lightingModel = .phong
            }
        }
    }
}
