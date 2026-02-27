import Foundation
import RealityKit

/// Loads and caches GLB (binary GLTF) 3D entities from the app bundle using RealityKit.
///
/// SceneKit's ModelIO bridge (`SCNScene(mdlAsset:)`, `SCNNode(mdlObject:)`) was removed
/// in iOS 26. RealityKit's `Entity.load(contentsOf:)` is the replacement.
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
@MainActor
final class GLBAssetLoader {
    static let shared = GLBAssetLoader()

    private var cache: [String: Entity] = [:]

    private init() {}

    /// Returns true when the GLB file is present in the app bundle.
    func isAvailable(named name: String) -> Bool {
        let url = Bundle.main.url(forResource: name, withExtension: "glb")
        print("[GLBAssetLoader] isAvailable('\(name)'): \(url != nil ? "✅ \(url!.path)" : "❌ not found in bundle")")
        return url != nil
    }

    /// Loads the named GLB (or returns a cached clone) as a RealityKit Entity.
    /// Returns nil when the file is not present in the bundle — callers show 2D fallback.
    func entity(named name: String) async -> Entity? {
        // Fast path: return a clone of the cached master entity
        if let cached = cache[name] {
            print("[GLBAssetLoader] entity('\(name)'): ✅ returning cached clone")
            return cached.clone(recursive: true)
        }

        guard let url = Bundle.main.url(forResource: name, withExtension: "glb") else {
            print("[GLBAssetLoader] entity('\(name)'): ❌ no bundle URL — file missing from bundle")
            return nil
        }

        print("[GLBAssetLoader] entity('\(name)'): loading from \(url.path)")

        do {
            let loaded = try await Entity.load(contentsOf: url)
            print("[GLBAssetLoader] entity('\(name)'): ✅ loaded — children: \(loaded.children.count)")
            cache[name] = loaded
            return loaded.clone(recursive: true)
        } catch {
            print("[GLBAssetLoader] entity('\(name)'): ❌ Entity.load failed — \(error)")
            return nil
        }
    }
}
