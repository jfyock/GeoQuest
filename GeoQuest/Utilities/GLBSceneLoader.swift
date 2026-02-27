import Foundation
import SceneKit
import ModelIO

/// Loads GLB assets from the app bundle using ModelIO → SCNScene and caches
/// the resulting SCNNode trees.
///
/// The RealityKit/USDC pathway (MDLAsset.export → USDC → Entity.load) loses
/// all mesh geometry during export, producing entities with zero visual bounds.
/// SceneKit's SCNScene(mdlAsset:) is specifically designed to consume ModelIO
/// assets and correctly preserves GLB mesh data, materials, and transforms.
///
/// Cache note: SCNNode.clone() shares geometry objects, so materials modified
/// via applyBodyColor affect the cached master — this is intentional since body
/// colour is always re-applied from config on every load.
@MainActor
final class GLBSceneLoader {
    static let shared = GLBSceneLoader()
    private var cache: [String: SCNNode] = [:]
    private init() {}

    /// Returns a cloned SCNNode tree for the named GLB, loading and caching on
    /// first call.  Returns nil when the file is missing or the asset is empty.
    func node(named name: String) async -> SCNNode? {
        if let cached = cache[name] {
            print("[GLBSceneLoader] '\(name)': ✅ returning cached clone")
            return cached.clone()
        }

        guard let url = Bundle.main.url(forResource: name, withExtension: "glb") else {
            print("[GLBSceneLoader] '\(name)': ❌ not in bundle")
            return nil
        }

        print("[GLBSceneLoader] '\(name)': loading via MDLAsset → SCNScene")
        let result = await withCheckedContinuation { (cont: CheckedContinuation<SCNNode?, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let asset = MDLAsset(url: url)
                asset.loadTextures()
                let scene = SCNScene(mdlAsset: asset)
                let root = scene.rootNode
                let count = root.childNodes.count
                print("[GLBSceneLoader] '\(name)': ✅ loaded — child nodes: \(count)")
                cont.resume(returning: count > 0 ? root.clone() : nil)
            }
        }

        if let node = result {
            cache[name] = node
            return node.clone()
        }
        return nil
    }
}
