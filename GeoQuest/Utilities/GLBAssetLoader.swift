import Foundation
import RealityKit
import ModelIO

/// Loads and caches GLB 3D entities from the app bundle as RealityKit ModelEntities.
///
/// Loading strategy (tried in order):
///   1. Direct `Entity.load(contentsOf:)` — succeeds if iOS 26 ships a GLB importer.
///   2. MDLAsset → MeshDescriptor → MeshResource → ModelEntity — builds RealityKit
///      geometry directly from ModelIO vertex buffers, completely bypassing file
///      export.  MDLAsset.export(to: .usdc/.usdz) strips mesh geometry and is
///      intentionally not used.
///
/// Place GLB files in GeoQuest/Resources/3D/; Xcode's file-system synchronised
/// group copies them to the bundle automatically.
@MainActor
final class GLBAssetLoader {
    static let shared = GLBAssetLoader()
    private var cache: [String: Entity] = [:]
    private init() {}

    /// Returns true when the named GLB file exists in the app bundle.
    func isAvailable(named name: String) -> Bool {
        let url = Bundle.main.url(forResource: name, withExtension: "glb")
        print("[GLBAssetLoader] isAvailable('\(name)'): \(url != nil ? "✅ \(url!.path)" : "❌ not found in bundle")")
        return url != nil
    }

    /// Returns a ready-to-use clone of the named GLB entity, loading and caching
    /// on first call.  Returns nil when the file is missing or all load strategies fail.
    func entity(named name: String) async -> Entity? {
        if let cached = cache[name] {
            print("[GLBAssetLoader] entity('\(name)'): ✅ returning cached clone")
            return cached.clone(recursive: true)
        }

        guard let glbURL = Bundle.main.url(forResource: name, withExtension: "glb") else {
            print("[GLBAssetLoader] entity('\(name)'): ❌ no bundle URL — file missing from bundle")
            return nil
        }

        // Strategy 1: direct RealityKit load
        print("[GLBAssetLoader] entity('\(name)'): trying Entity.load(contentsOf:)")
        do {
            let entity = try await Entity.load(contentsOf: glbURL)
            print("[GLBAssetLoader] entity('\(name)'): ✅ direct GLB load — children: \(entity.children.count)")
            cache[name] = entity
            return entity.clone(recursive: true)
        } catch {
            print("[GLBAssetLoader] entity('\(name)'): ❌ Entity.load failed: \(error)")
        }

        // Strategy 2: MDLAsset → MeshDescriptor → ModelEntity
        print("[GLBAssetLoader] entity('\(name)'): trying MDLAsset (canImport glb=\(MDLAsset.canImportFileExtension("glb")))")
        let built = await withCheckedContinuation { (cont: CheckedContinuation<Entity?, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                cont.resume(returning: Self.buildEntity(from: glbURL, label: name))
            }
        }

        if let entity = built {
            print("[GLBAssetLoader] entity('\(name)'): ✅ built from MDLAsset")
            cache[name] = entity
            return entity.clone(recursive: true)
        }

        print("[GLBAssetLoader] entity('\(name)'): ❌ all load strategies failed")
        return nil
    }

    // MARK: - MDLAsset → Entity

    private static func buildEntity(from glbURL: URL, label: String) -> Entity? {
        let asset = MDLAsset(url: glbURL)
        let root = Entity()
        var meshCount = 0

        print("[GLBAssetLoader] buildEntity('\(label)'): asset.count=\(asset.count)")

        // Primary: MDLAsset.childObjects(of:) recursively searches the entire
        // asset hierarchy — more reliable than walking children.objects manually.
        let allMeshes = asset.childObjects(of: MDLMesh.self)
        print("[GLBAssetLoader] buildEntity('\(label)'): childObjects(MDLMesh)=\(allMeshes.count)")

        for case let mdlMesh as MDLMesh in allMeshes {
            print("[GLBAssetLoader]   mesh '\(mdlMesh.name)' vertices=\(mdlMesh.vertexCount) submeshes=\(mdlMesh.submeshes?.count ?? 0)")
            if let modelEntity = makeModelEntity(from: mdlMesh) {
                root.addChild(modelEntity)
                meshCount += 1
            }
        }

        // Fallback: manual recursive traversal via children.objects
        if meshCount == 0 {
            print("[GLBAssetLoader] buildEntity('\(label)'): childObjects found nothing — trying recursive traversal")
            func process(_ object: MDLObject, depth: Int = 0) {
                let indent = String(repeating: "  ", count: depth)
                print("[GLBAssetLoader]   \(indent)\(type(of: object)) '\(object.name)' children=\(object.children.count)")
                if let mdlMesh = object as? MDLMesh,
                   let modelEntity = makeModelEntity(from: mdlMesh) {
                    root.addChild(modelEntity)
                    meshCount += 1
                }
                for child in object.children.objects { process(child, depth: depth + 1) }
            }
            for i in 0..<asset.count { process(asset.object(at: i)) }
        }

        print("[GLBAssetLoader] buildEntity('\(label)'): \(meshCount) mesh(es) built")
        return meshCount > 0 ? root : nil
    }

    /// Converts one MDLMesh to a RealityKit ModelEntity via MeshDescriptor.
    /// Extracts positions, normals, and UVs using ModelIO's attribute-data API
    /// which handles vertex-buffer layout conversion automatically.
    private static func makeModelEntity(from mdlMesh: MDLMesh) -> ModelEntity? {
        let vertexCount = mdlMesh.vertexCount
        guard vertexCount > 0 else { return nil }

        // --- Positions (required) ---
        guard let posData = mdlMesh.vertexAttributeData(
            forAttributeNamed: MDLVertexAttributePosition, as: .float3
        ) else { return nil }

        var positions: [SIMD3<Float>] = []
        positions.reserveCapacity(vertexCount)
        for i in 0..<vertexCount {
            let ptr = UnsafeRawPointer(posData.dataStart.advanced(by: i * posData.stride))
            positions.append(ptr.load(as: SIMD3<Float>.self))
        }

        // --- Normals (optional, improves shading) ---
        var normals: [SIMD3<Float>]? = nil
        if let normData = mdlMesh.vertexAttributeData(
            forAttributeNamed: MDLVertexAttributeNormal, as: .float3
        ) {
            var ns: [SIMD3<Float>] = []
            ns.reserveCapacity(vertexCount)
            for i in 0..<vertexCount {
                let ptr = UnsafeRawPointer(normData.dataStart.advanced(by: i * normData.stride))
                ns.append(ptr.load(as: SIMD3<Float>.self))
            }
            normals = ns
        }

        // --- UV coordinates (optional, needed for texture mapping) ---
        var uvs: [SIMD2<Float>]? = nil
        if let uvData = mdlMesh.vertexAttributeData(
            forAttributeNamed: MDLVertexAttributeTextureCoordinate, as: .float2
        ) {
            var us: [SIMD2<Float>] = []
            us.reserveCapacity(vertexCount)
            for i in 0..<vertexCount {
                let ptr = UnsafeRawPointer(uvData.dataStart.advanced(by: i * uvData.stride))
                us.append(ptr.load(as: SIMD2<Float>.self))
            }
            uvs = us
        }

        // --- Indices from all triangle submeshes ---
        var allIndices: [UInt32] = []
        for case let submesh as MDLSubmesh in mdlMesh.submeshes ?? [] {
            guard submesh.geometryType == .triangles else { continue }
            let ib = submesh.indexBuffer(asIndexType: .uInt32)
            let ibMap = ib.map()
            allIndices += Array(UnsafeBufferPointer(
                start: ibMap.bytes.assumingMemoryBound(to: UInt32.self),
                count: submesh.indexCount
            ))
        }
        guard !allIndices.isEmpty else { return nil }

        do {
            var descriptor = MeshDescriptor(name: mdlMesh.name)
            descriptor.positions = MeshBuffer(positions)
            if let n = normals { descriptor.normals = MeshBuffer(n) }
            if let u = uvs { descriptor.textureCoordinates = MeshBuffer(u) }
            descriptor.primitives = .triangles(allIndices)

            let mesh = try MeshResource.generate(from: [descriptor])
            return ModelEntity(mesh: mesh, materials: [SimpleMaterial()])
        } catch {
            print("[GLBAssetLoader] makeModelEntity('\(mdlMesh.name)'): ❌ \(error)")
            return nil
        }
    }
}
