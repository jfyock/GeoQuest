import Foundation
import RealityKit

/// Loads and caches USDZ 3D entities from the app bundle using RealityKit.
///
/// RealityKit's `Entity.load(contentsOf:)` supports USDZ (`.usdz`) and Reality
/// Composer bundles (`.reality`). GLB/GLTF is NOT a supported input format —
/// convert GLB files to USDZ using Reality Composer Pro, Blender, or
/// `xcrun usdz_converter` before adding them to the project.
///
/// Place USDZ files anywhere inside the GeoQuest/ project directory — Xcode's
/// file-system synchronized group will automatically include them in the bundle.
///
/// Expected files (USDZ format):
///   Avatar body:        avatar_body_default.usdz
///   Avatar accessories: avatar_acc_hat.usdz, avatar_acc_crown.usdz,
///                       avatar_acc_glasses.usdz, avatar_acc_sunglasses.usdz,
///                       avatar_acc_headband.usdz, avatar_acc_antenna.usdz,
///                       avatar_acc_bow.usdz
///   Map markers:        map_marker_player.usdz
///   Map objects:        (reserved for future use)
@MainActor
final class GLBAssetLoader {
    static let shared = GLBAssetLoader()

    private var cache: [String: Entity] = [:]

    private init() {}

    /// Returns true when the GLB file is present in the app bundle.
    func isAvailable(named name: String) -> Bool {
        let url = Bundle.main.url(forResource: name, withExtension: "usdz")
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

        guard let url = Bundle.main.url(forResource: name, withExtension: "usdz") else {
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
