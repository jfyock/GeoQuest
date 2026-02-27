import SceneKit
import ModelIO

/// Loads and caches GLB (binary GLTF) 3D scenes from the app bundle.
///
/// Place GLB files anywhere inside the GeoQuest/ project directory — Xcode's
/// file-system synchronized group will automatically include them in the bundle.
///
/// Expected files:
///   Avatar body:        avatar_body_default.glb
///   Avatar accessories: avatar_acc_hat.glb, avatar_acc_crown.glb,
///                       avatar_acc_glasses.glb, avatar_acc_sunglasses.glb,
///                       avatar_acc_headband.glb, avatar_acc_antenna.glb,
///                       avatar_acc_bow.glb
///   Map markers:        map_marker_quest.glb, map_marker_player.glb
///   Map objects:        map_object_tree.glb, map_object_chest.glb, map_object_flag.glb
final class GLBAssetLoader: @unchecked Sendable {
    static let shared = GLBAssetLoader()

    private var cache: [String: SCNScene] = [:]
    private let lock = NSLock()

    private init() {}

    /// Returns a cached or freshly loaded SCNScene for the given GLB model name (no extension).
    /// Returns nil if the file is not found in the bundle, allowing graceful 2D fallback.
    func scene(named name: String) -> SCNScene? {
        lock.lock()
        defer { lock.unlock() }

        if let cached = cache[name] {
            return cached
        }

        guard let url = Bundle.main.url(forResource: name, withExtension: "glb") else {
            return nil
        }

        let asset = MDLAsset(url: url)
        asset.loadTextures()
        let scene = SCNScene(mdlAsset: asset)
        cache[name] = scene
        return scene
    }

    /// Returns true when the GLB file is present in the app bundle.
    func isAvailable(named name: String) -> Bool {
        Bundle.main.url(forResource: name, withExtension: "glb") != nil
    }

    /// Returns a deep-cloned node from the named GLB scene so each call site
    /// gets independent geometry and materials (safe to tint/transform).
    func clonedRootNode(named name: String) -> SCNNode? {
        guard let scene = scene(named: name) else { return nil }
        return deepClone(scene.rootNode)
    }

    // MARK: - Private

    /// Creates a deep copy of a node hierarchy with independent material instances,
    /// so color/material changes on the clone don't affect the cached original.
    private func deepClone(_ node: SCNNode) -> SCNNode {
        let cloned = node.clone()
        cloned.enumerateHierarchy { n, _ in
            guard let geo = n.geometry else { return }
            let geoCopy = geo.copy() as! SCNGeometry
            geoCopy.materials = geo.materials.map { mat in
                let copy = mat.copy() as! SCNMaterial
                return copy
            }
            n.geometry = geoCopy
        }
        return cloned
    }
}
