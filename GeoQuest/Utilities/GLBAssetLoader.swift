import Foundation
import RealityKit
import ModelIO

/// Loads and caches GLB 3D entities from the app bundle using RealityKit.
///
/// RealityKit's `Entity.load(contentsOf:)` has no GLB importer. This loader
/// bridges that gap at runtime using ModelIO, which has native GLB/GLTF support
/// (iOS 16+). Each GLB is imported via `MDLAsset`, re-exported to a temporary
/// USDZ file, loaded by RealityKit (which fully supports USDZ), and then the
/// temporary file is deleted. Textures embedded in the GLB are preserved through
/// the export.
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
///   Map markers:        map_marker_player.glb
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
    ///
    /// Pipeline: GLB (bundle) → MDLAsset → temp USDZ → Entity.load → cached.
    /// Returns nil when the file is missing or conversion/load fails; callers
    /// should fall back to a 2D representation.
    func entity(named name: String) async -> Entity? {
        // Fast path: return a clone of the cached master entity
        if let cached = cache[name] {
            print("[GLBAssetLoader] entity('\(name)'): ✅ returning cached clone")
            return cached.clone(recursive: true)
        }

        guard let glbURL = Bundle.main.url(forResource: name, withExtension: "glb") else {
            print("[GLBAssetLoader] entity('\(name)'): ❌ no bundle URL — file missing from bundle")
            return nil
        }

        print("[GLBAssetLoader] entity('\(name)'): converting GLB → USDZ via ModelIO")

        // Unique temp file per load to avoid collisions if called concurrently
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name)_\(UUID().uuidString).usdz")

        // MDLAsset import/export is CPU-bound — run off the main actor
        let exported = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let asset = MDLAsset(url: glbURL)
                do {
                    try asset.export(to: tempURL)
                    cont.resume(returning: true)
                } catch {
                    print("[GLBAssetLoader] entity('\(name)'): ❌ MDLAsset.export threw — \(error)")
                    cont.resume(returning: false)
                }
            }
        }

        guard exported else { return nil }

        print("[GLBAssetLoader] entity('\(name)'): loading converted USDZ with RealityKit")

        do {
            let loaded = try await Entity.load(contentsOf: tempURL)
            print("[GLBAssetLoader] entity('\(name)'): ✅ loaded — children: \(loaded.children.count)")
            try? FileManager.default.removeItem(at: tempURL)
            cache[name] = loaded
            return loaded.clone(recursive: true)
        } catch {
            print("[GLBAssetLoader] entity('\(name)'): ❌ Entity.load failed — \(error)")
            try? FileManager.default.removeItem(at: tempURL)
            return nil
        }
    }
}
