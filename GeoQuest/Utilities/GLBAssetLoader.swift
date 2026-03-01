import Foundation
import RealityKit
import UIKit

/// Loads and caches GLB 3D entities from the app bundle as RealityKit ModelEntities.
///
/// Neither Entity.load (throws `noImporter`) nor MDLAsset (`canImportFileExtension`
/// returns false) supports GLB on this iOS version, so we parse the binary format
/// ourselves in two phases:
///
///   Phase 1 — background thread: read the GLB file, extract geometry arrays and
///             decode embedded images to CGImage.  No RealityKit calls.
///   Phase 2 — main actor: create TextureResource / MeshResource / ModelEntity.
///             GPU-bound RealityKit work must happen here to avoid crashes.
@MainActor
final class GLBAssetLoader {
    static let shared = GLBAssetLoader()
    private var cache: [String: Entity] = [:]
    private init() {}

    // MARK: - Public API

    func isAvailable(named name: String) -> Bool {
        let url = Bundle.main.url(forResource: name, withExtension: "glb")
        print("[GLBAssetLoader] isAvailable('\(name)'): \(url != nil ? "✅ \(url!.path)" : "❌ not found in bundle")")
        return url != nil
    }

    func entity(named name: String) async -> Entity? {
        if let cached = cache[name] {
            print("[GLBAssetLoader] entity('\(name)'): ✅ returning cached clone")
            return cached.clone(recursive: true)
        }

        guard let glbURL = Bundle.main.url(forResource: name, withExtension: "glb") else {
            print("[GLBAssetLoader] entity('\(name)'): ❌ no bundle URL — file missing from bundle")
            return nil
        }

        // Strategy 1: native importer — kept for forward compatibility
        do {
            let entity = try await Entity.load(contentsOf: glbURL)
            print("[GLBAssetLoader] entity('\(name)'): ✅ direct load")
            cache[name] = entity
            return entity.clone(recursive: true)
        } catch {
            print("[GLBAssetLoader] entity('\(name)'): ❌ Entity.load: \(error)")
        }

        // Strategy 2: self-contained GLB 2.0 binary parser, two-phase

        // Phase 1: pure data extraction on a background thread (no RealityKit calls)
        print("[GLBAssetLoader] entity('\(name)'): parsing GLB binary (background)")
        let parsed = await withCheckedContinuation { (cont: CheckedContinuation<ParsedGLBData?, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                cont.resume(returning: GLBAssetLoader.parseGLBData(url: glbURL, label: name))
            }
        }

        guard let parsed else {
            print("[GLBAssetLoader] entity('\(name)'): ❌ GLB parse failed")
            return nil
        }

        // Phase 2: build RealityKit objects back on the main actor
        print("[GLBAssetLoader] entity('\(name)'): building RealityKit objects (main actor)")
        let entity = buildEntity(from: parsed, label: name)

        if let entity {
            print("[GLBAssetLoader] entity('\(name)'): ✅ built from GLB parser")
            cache[name] = entity
            return entity.clone(recursive: true)
        }

        print("[GLBAssetLoader] entity('\(name)'): ❌ all load strategies failed")
        return nil
    }

    // MARK: - Phase 2: RealityKit object creation (main actor)

    private func buildEntity(from parsed: ParsedGLBData, label: String) -> Entity? {
        // TextureResource.generate and MeshResource.generate touch the GPU —
        // they must be called on the main actor in iOS 26.

        var textureResources: [Int: TextureResource] = [:]
        for (ti, cgImage) in parsed.textureCGImages {
            if let res = try? TextureResource.generate(from: cgImage,
                                                       options: .init(semantic: .color)) {
                textureResources[ti] = res
                print("[GLBAssetLoader] buildEntity('\(label)'): texture[\(ti)] ✅")
            } else {
                print("[GLBAssetLoader] buildEntity('\(label)'): texture[\(ti)] ❌ TextureResource failed")
            }
        }

        let root = Entity()
        var meshCount = 0

        for (pi, prim) in parsed.primitives.enumerated() {
            var desc = MeshDescriptor(name: prim.meshName)
            desc.positions = MeshBuffer(prim.positions)
            if prim.normals.count == prim.positions.count {
                desc.normals = MeshBuffer(prim.normals)
            }
            if prim.uvs.count == prim.positions.count {
                desc.textureCoordinates = MeshBuffer(prim.uvs)
            }
            desc.primitives = .triangles(prim.indices)

            guard let meshRes = try? MeshResource.generate(from: [desc]) else {
                print("[GLBAssetLoader] buildEntity('\(label)'): prim[\(pi)] ❌ MeshResource failed")
                continue
            }

            var mat = SimpleMaterial()
            if let md = prim.materialData {
                if let texIdx = md.baseColorTextureIndex,
                   let res = textureResources[texIdx] {
                    mat.color = .init(texture: .init(res))
                } else if let f = md.baseColorFactor, f.count >= 3 {
                    mat.color = .init(tint: UIColor(
                        red:   CGFloat(f[0]),
                        green: CGFloat(f[1]),
                        blue:  CGFloat(f[2]),
                        alpha: CGFloat(f.count > 3 ? f[3] : 1.0)))
                }
                mat.metallic  = .float(md.metallic)
                mat.roughness = .float(md.roughness)
            }

            let model = ModelEntity(mesh: meshRes, materials: [mat])
            model.name = prim.meshName
            root.addChild(model)
            meshCount += 1
            print("[GLBAssetLoader] buildEntity('\(label)'): prim[\(pi)] ✅ \(prim.positions.count)v \(prim.indices.count / 3)t")
        }

        print("[GLBAssetLoader] buildEntity('\(label)'): \(meshCount) entities total")
        return meshCount > 0 ? root : nil
    }

    // MARK: - Phase 1: pure binary parsing (no RealityKit, background-safe)

    private struct MaterialData {
        let baseColorTextureIndex: Int?
        let baseColorFactor: [Double]?
        let metallic: Float
        let roughness: Float
    }

    private struct GLBPrimitive {
        let meshName: String
        let positions: [SIMD3<Float>]
        let normals:   [SIMD3<Float>]
        let uvs:       [SIMD2<Float>]
        let indices:   [UInt32]
        let materialData: MaterialData?
    }

    private struct ParsedGLBData {
        let primitives:     [GLBPrimitive]
        let textureCGImages: [Int: CGImage]
    }

    /// Reads the GLB file, extracts geometry arrays, and decodes embedded images
    /// to CGImage.  Does NOT create any RealityKit objects — safe on any thread.
    private static func parseGLBData(url: URL, label: String) -> ParsedGLBData? {
        guard let file = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            print("[GLBAssetLoader] parseGLBData('\(label)'): ❌ cannot read file")
            return nil
        }

        // ── Header ────────────────────────────────────────────────────────────
        guard file.count >= 12,
              file.gltfU32(at: 0) == 0x46546C67,  // "glTF"
              file.gltfU32(at: 4) == 2             // version 2
        else {
            print("[GLBAssetLoader] parseGLBData('\(label)'): ❌ not a valid GLB 2.0")
            return nil
        }

        // ── Chunks ────────────────────────────────────────────────────────────
        var jsonChunk: Data?
        var binChunk:  Data?
        var pos = 12
        while pos + 8 <= file.count {
            let chunkLen  = Int(file.gltfU32(at: pos))
            let chunkType =     file.gltfU32(at: pos + 4)
            pos += 8
            let end = pos + chunkLen
            guard end <= file.count else { break }
            switch chunkType {
            case 0x4E4F534A: jsonChunk = file.subdata(in: pos..<end)  // JSON
            case 0x004E4942: binChunk  = file.subdata(in: pos..<end)  // BIN
            default: break
            }
            pos = end
        }

        guard let jsonChunk,
              let gltf = (try? JSONSerialization.jsonObject(with: jsonChunk)) as? [String: Any]
        else {
            print("[GLBAssetLoader] parseGLBData('\(label)'): ❌ JSON chunk missing/invalid")
            return nil
        }
        let bin = binChunk ?? Data()

        let accessors   = gltf["accessors"]   as? [[String: Any]] ?? []
        let bufferViews = gltf["bufferViews"] as? [[String: Any]] ?? []
        let meshes      = gltf["meshes"]      as? [[String: Any]] ?? []
        let materials   = gltf["materials"]   as? [[String: Any]] ?? []
        let textures    = gltf["textures"]    as? [[String: Any]] ?? []
        let images      = gltf["images"]      as? [[String: Any]] ?? []
        print("[GLBAssetLoader] parseGLBData('\(label)'): meshes=\(meshes.count) mats=\(materials.count) textures=\(textures.count)")

        // ── Accessor helper ───────────────────────────────────────────────────
        func accessorData(_ idx: Int) -> (bytes: Data, count: Int, stride: Int, componentType: Int)? {
            guard idx < accessors.count else { return nil }
            let acc      = accessors[idx]
            let count    = acc["count"]         as? Int    ?? 0
            let byteOff  = acc["byteOffset"]    as? Int    ?? 0
            let compType = acc["componentType"] as? Int    ?? 5126
            let typeStr  = acc["type"]          as? String ?? "SCALAR"
            guard let bvIdx = acc["bufferView"] as? Int, bvIdx < bufferViews.count else { return nil }
            let bv       = bufferViews[bvIdx]
            let bvOff    = bv["byteOffset"] as? Int ?? 0
            let bvLen    = bv["byteLength"] as? Int ?? 0
            let bvStride = bv["byteStride"] as? Int ?? 0
            let compSize: Int
            switch compType {
            case 5120, 5121: compSize = 1
            case 5122, 5123: compSize = 2
            default:         compSize = 4
            }
            let compCount: Int
            switch typeStr {
            case "SCALAR": compCount = 1
            case "VEC2":   compCount = 2
            case "VEC3":   compCount = 3
            case "VEC4":   compCount = 4
            default:       compCount = 1
            }
            let stride = bvStride > 0 ? bvStride : compSize * compCount
            let start  = bvOff + byteOff
            let end    = bvOff + bvLen
            guard start >= 0, end <= bin.count, start < end else { return nil }
            return (bin.subdata(in: start..<end), count, stride, compType)
        }

        // ── Image decoding (CPU only — no GPU upload yet) ─────────────────────
        var textureCGImages: [Int: CGImage] = [:]
        for (ti, tex) in textures.enumerated() {
            guard let srcIdx = tex["source"] as? Int, srcIdx < images.count else { continue }
            let img   = images[srcIdx]
            guard let bvIdx = img["bufferView"] as? Int, bvIdx < bufferViews.count else { continue }
            let bv    = bufferViews[bvIdx]
            let bvOff = bv["byteOffset"] as? Int ?? 0
            let bvLen = bv["byteLength"] as? Int ?? 0
            guard bvOff + bvLen <= bin.count else { continue }
            let imgData = bin.subdata(in: bvOff..<(bvOff + bvLen))
            guard let uiImg = UIImage(data: imgData), let cg = uiImg.cgImage else {
                print("[GLBAssetLoader] parseGLBData('\(label)'): image[\(ti)] ❌ decode failed")
                continue
            }
            textureCGImages[ti] = cg
            print("[GLBAssetLoader] parseGLBData('\(label)'): image[\(ti)] decoded \(bvLen) bytes")
        }

        // ── Material parsing ──────────────────────────────────────────────────
        func parseMaterial(_ idx: Int?) -> MaterialData? {
            guard let idx, idx >= 0, idx < materials.count else { return nil }
            let m = materials[idx]
            guard let pbr = m["pbrMetallicRoughness"] as? [String: Any] else { return nil }
            return MaterialData(
                baseColorTextureIndex: (pbr["baseColorTexture"] as? [String: Any])?["index"] as? Int,
                baseColorFactor: pbr["baseColorFactor"] as? [Double],
                metallic:  Float(pbr["metallicFactor"]  as? Double ?? 0),
                roughness: Float(pbr["roughnessFactor"] as? Double ?? 0.8))
        }

        // ── Geometry extraction ───────────────────────────────────────────────
        func vec3s(_ bytes: Data, _ count: Int, _ stride: Int) -> [SIMD3<Float>] {
            var out = [SIMD3<Float>](); out.reserveCapacity(count)
            bytes.withUnsafeBytes { r in
                for i in 0..<count {
                    let b = i * stride; guard b + 12 <= r.count else { break }
                    out.append(SIMD3(r.load(fromByteOffset: b,     as: Float.self),
                                     r.load(fromByteOffset: b + 4, as: Float.self),
                                     r.load(fromByteOffset: b + 8, as: Float.self)))
                }
            }
            return out
        }

        func vec2s(_ bytes: Data, _ count: Int, _ stride: Int) -> [SIMD2<Float>] {
            var out = [SIMD2<Float>](); out.reserveCapacity(count)
            bytes.withUnsafeBytes { r in
                for i in 0..<count {
                    let b = i * stride; guard b + 8 <= r.count else { break }
                    out.append(SIMD2(r.load(fromByteOffset: b,     as: Float.self),
                                     r.load(fromByteOffset: b + 4, as: Float.self)))
                }
            }
            return out
        }

        var primitives: [GLBPrimitive] = []

        for (mi, mesh) in meshes.enumerated() {
            for (pi, prim) in (mesh["primitives"] as? [[String: Any]] ?? []).enumerated() {
                let attrs = prim["attributes"] as? [String: Int] ?? [:]

                guard let posIdx = attrs["POSITION"],
                      let (posBytes, vertCount, posStride, _) = accessorData(posIdx),
                      vertCount > 0
                else {
                    print("[GLBAssetLoader] parseGLBData('\(label)'): m\(mi)p\(pi) ❌ no POSITION")
                    continue
                }

                let positions = vec3s(posBytes, vertCount, posStride)

                var normals = [SIMD3<Float>]()
                if let nIdx = attrs["NORMAL"],
                   let (nB, nC, nS, _) = accessorData(nIdx) { normals = vec3s(nB, nC, nS) }

                var uvs = [SIMD2<Float>]()
                if let uIdx = attrs["TEXCOORD_0"],
                   let (uB, uC, uS, _) = accessorData(uIdx) { uvs = vec2s(uB, uC, uS) }

                var indices = [UInt32]()
                if let iAccIdx = prim["indices"] as? Int,
                   let (iBytes, iCount, _, iComp) = accessorData(iAccIdx) {
                    indices.reserveCapacity(iCount)
                    iBytes.withUnsafeBytes { r in
                        switch iComp {
                        case 5121:
                            for i in 0..<iCount { indices.append(UInt32(r[i])) }
                        case 5123:
                            for i in 0..<iCount {
                                let o = i * 2; guard o + 2 <= r.count else { break }
                                indices.append(UInt32(r.load(fromByteOffset: o, as: UInt16.self)))
                            }
                        case 5125:
                            for i in 0..<iCount {
                                let o = i * 4; guard o + 4 <= r.count else { break }
                                indices.append(r.load(fromByteOffset: o, as: UInt32.self))
                            }
                        default: break
                        }
                    }
                }

                guard !indices.isEmpty else {
                    print("[GLBAssetLoader] parseGLBData('\(label)'): m\(mi)p\(pi) ❌ no indices")
                    continue
                }

                let trimmed = Array(indices.prefix(indices.count - indices.count % 3))
                primitives.append(GLBPrimitive(
                    meshName:     mesh["name"] as? String ?? label,
                    positions:    positions,
                    normals:      normals,
                    uvs:          uvs,
                    indices:      trimmed,
                    materialData: parseMaterial(prim["material"] as? Int)))
                print("[GLBAssetLoader] parseGLBData('\(label)'): m\(mi)p\(pi) ✅ \(positions.count)v \(trimmed.count / 3)t")
            }
        }

        guard !primitives.isEmpty else {
            print("[GLBAssetLoader] parseGLBData('\(label)'): ❌ no valid primitives")
            return nil
        }
        return ParsedGLBData(primitives: primitives, textureCGImages: textureCGImages)
    }
}

// MARK: - Data helpers

private extension Data {
    /// Loads a little-endian UInt32 at the given byte offset.
    func gltfU32(at offset: Int) -> UInt32 {
        withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }
    }
}
