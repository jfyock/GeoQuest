import Foundation
import RealityKit
import UIKit

/// Loads and caches GLB 3D entities from the app bundle as RealityKit ModelEntities.
///
/// Both RealityKit's Entity.load and ModelIO's MDLAsset lack a GLB importer on
/// this iOS version (Entity.load throws `noImporter`, MDLAsset.canImportFileExtension
/// returns false).  This loader implements a self-contained GLB 2.0 binary parser:
/// it reads the JSON + binary chunks directly, maps every accessor/bufferView into
/// Swift geometry arrays, builds MeshDescriptors, and loads any embedded PNG/JPEG
/// textures as TextureResource objects.
@MainActor
final class GLBAssetLoader {
    static let shared = GLBAssetLoader()
    private var cache: [String: Entity] = [:]
    private init() {}

    // MARK: - Public API

    /// Returns true when the named GLB file exists in the app bundle.
    func isAvailable(named name: String) -> Bool {
        let url = Bundle.main.url(forResource: name, withExtension: "glb")
        print("[GLBAssetLoader] isAvailable('\(name)'): \(url != nil ? "✅ \(url!.path)" : "❌ not found in bundle")")
        return url != nil
    }

    /// Returns a ready-to-use clone of the named GLB entity, loading and caching
    /// on first call.  Returns nil when the file is missing or parsing fails.
    func entity(named name: String) async -> Entity? {
        if let cached = cache[name] {
            print("[GLBAssetLoader] entity('\(name)'): ✅ returning cached clone")
            return cached.clone(recursive: true)
        }

        guard let glbURL = Bundle.main.url(forResource: name, withExtension: "glb") else {
            print("[GLBAssetLoader] entity('\(name)'): ❌ no bundle URL — file missing from bundle")
            return nil
        }

        // Strategy 1: native importer — kept for future iOS compatibility
        do {
            let entity = try await Entity.load(contentsOf: glbURL)
            print("[GLBAssetLoader] entity('\(name)'): ✅ direct load")
            cache[name] = entity
            return entity.clone(recursive: true)
        } catch {
            print("[GLBAssetLoader] entity('\(name)'): ❌ Entity.load: \(error)")
        }

        // Strategy 2: self-contained GLB 2.0 binary parser
        print("[GLBAssetLoader] entity('\(name)'): parsing GLB binary")
        let built = await withCheckedContinuation { (cont: CheckedContinuation<Entity?, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                cont.resume(returning: Self.parseGLB(url: glbURL, label: name))
            }
        }

        if let entity = built {
            print("[GLBAssetLoader] entity('\(name)'): ✅ built from GLB parser")
            cache[name] = entity
            return entity.clone(recursive: true)
        }

        print("[GLBAssetLoader] entity('\(name)'): ❌ all load strategies failed")
        return nil
    }

    // MARK: - GLB 2.0 Binary Parser

    /// Parses a GLB 2.0 binary file and returns a RealityKit entity tree.
    /// Safe to call from a background thread.
    private static func parseGLB(url: URL, label: String) -> Entity? {

        // ── Read file ─────────────────────────────────────────────────────────
        guard let file = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            print("[GLBAssetLoader] parseGLB('\(label)'): ❌ cannot read file")
            return nil
        }

        // ── Header (12 bytes: magic u32, version u32, length u32) ─────────────
        guard file.count >= 12,
              file.gltfU32(at: 0) == 0x46546C67,  // "glTF"
              file.gltfU32(at: 4) == 2             // version 2
        else {
            print("[GLBAssetLoader] parseGLB('\(label)'): ❌ not a valid GLB 2.0")
            return nil
        }

        // ── Chunks (each: length u32, type u32, data[length]) ─────────────────
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
            case 0x004E4942: binChunk  = file.subdata(in: pos..<end)  // BIN\0
            default: break
            }
            pos = end
        }

        guard let jsonChunk,
              let gltf = (try? JSONSerialization.jsonObject(with: jsonChunk)) as? [String: Any]
        else {
            print("[GLBAssetLoader] parseGLB('\(label)'): ❌ missing/invalid JSON chunk")
            return nil
        }
        let bin = binChunk ?? Data()

        let accessors   = gltf["accessors"]   as? [[String: Any]] ?? []
        let bufferViews = gltf["bufferViews"] as? [[String: Any]] ?? []
        let meshes      = gltf["meshes"]      as? [[String: Any]] ?? []
        let materials   = gltf["materials"]   as? [[String: Any]] ?? []
        let textures    = gltf["textures"]    as? [[String: Any]] ?? []
        let images      = gltf["images"]      as? [[String: Any]] ?? []
        print("[GLBAssetLoader] parseGLB('\(label)'): meshes=\(meshes.count) mats=\(materials.count) textures=\(textures.count) accessors=\(accessors.count)")

        // ── Accessor reader ────────────────────────────────────────────────────
        // Returns a Data slice starting at element 0 of the accessor, plus
        // element count, per-element stride in bytes, and GLTF component type.
        func accessorData(_ idx: Int) -> (bytes: Data, count: Int, stride: Int, componentType: Int)? {
            guard idx < accessors.count else { return nil }
            let acc      = accessors[idx]
            let count    = acc["count"]         as? Int    ?? 0
            let byteOff  = acc["byteOffset"]    as? Int    ?? 0
            let compType = acc["componentType"] as? Int    ?? 5126  // default FLOAT
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
            default:         compSize = 4   // 5125 UNSIGNED_INT, 5126 FLOAT
            }
            let compCount: Int
            switch typeStr {
            case "SCALAR": compCount = 1
            case "VEC2":   compCount = 2
            case "VEC3":   compCount = 3
            case "VEC4":   compCount = 4
            default:       compCount = 1
            }
            let elemSize = compSize * compCount
            let stride   = bvStride > 0 ? bvStride : elemSize
            // Accessor byteOffset is relative to the bufferView start
            let start    = bvOff + byteOff
            let end      = bvOff + bvLen
            guard start >= 0, end <= bin.count, start < end else { return nil }
            return (bin.subdata(in: start..<end), count, stride, compType)
        }

        // ── Texture loading ────────────────────────────────────────────────────
        var textureResources: [Int: TextureResource] = [:]
        for (ti, tex) in textures.enumerated() {
            guard let srcIdx = tex["source"] as? Int, srcIdx < images.count else { continue }
            let img    = images[srcIdx]
            guard let bvIdx = img["bufferView"] as? Int, bvIdx < bufferViews.count else { continue }
            let bv     = bufferViews[bvIdx]
            let bvOff  = bv["byteOffset"] as? Int ?? 0
            let bvLen  = bv["byteLength"] as? Int ?? 0
            guard bvOff + bvLen <= bin.count else { continue }
            let imgData = bin.subdata(in: bvOff..<(bvOff + bvLen))
            guard let uiImg = UIImage(data: imgData), let cgImg = uiImg.cgImage else {
                print("[GLBAssetLoader] parseGLB('\(label)'): texture[\(ti)] ❌ UIImage decode failed")
                continue
            }
            if let res = try? TextureResource.generate(from: cgImg, options: .init(semantic: .color)) {
                textureResources[ti] = res
                print("[GLBAssetLoader] parseGLB('\(label)'): texture[\(ti)] ✅ \(bvLen) bytes")
            } else {
                print("[GLBAssetLoader] parseGLB('\(label)'): texture[\(ti)] ❌ TextureResource.generate failed")
            }
        }

        // ── Material builder ───────────────────────────────────────────────────
        func buildMaterial(_ matIdx: Int?) -> RealityKit.Material {
            var mat = SimpleMaterial()
            guard let matIdx, matIdx >= 0, matIdx < materials.count else { return mat }
            let m = materials[matIdx]
            if let pbr = m["pbrMetallicRoughness"] as? [String: Any] {
                // Base color texture takes priority over color factor
                if let bct    = pbr["baseColorTexture"] as? [String: Any],
                   let texIdx = bct["index"] as? Int,
                   let res    = textureResources[texIdx] {
                    mat.color = .init(texture: .init(res))
                } else if let f = pbr["baseColorFactor"] as? [Double], f.count >= 3 {
                    mat.color = .init(tint: UIColor(
                        red:   CGFloat(f[0]),
                        green: CGFloat(f[1]),
                        blue:  CGFloat(f[2]),
                        alpha: CGFloat(f.count > 3 ? f[3] : 1.0)))
                }
                mat.metallic  = .float(Float(pbr["metallicFactor"]  as? Double ?? 0))
                mat.roughness = .float(Float(pbr["roughnessFactor"] as? Double ?? 0.8))
            }
            return mat
        }

        // ── Build entity tree ──────────────────────────────────────────────────
        let root = Entity()
        var meshCount = 0

        for (mi, mesh) in meshes.enumerated() {
            let primitives = mesh["primitives"] as? [[String: Any]] ?? []
            for (pi, prim) in primitives.enumerated() {
                let attrs = prim["attributes"] as? [String: Int] ?? [:]

                guard let posIdx = attrs["POSITION"],
                      let (posBytes, vertCount, posStride, _) = accessorData(posIdx),
                      vertCount > 0
                else {
                    print("[GLBAssetLoader] parseGLB('\(label)'): m\(mi)p\(pi) ❌ no POSITION accessor")
                    continue
                }

                // ── Geometry extraction helpers ──────────────────────────────
                func vec3Array(_ bytes: Data, _ count: Int, _ stride: Int) -> [SIMD3<Float>] {
                    var out = [SIMD3<Float>]()
                    out.reserveCapacity(count)
                    bytes.withUnsafeBytes { r in
                        for i in 0..<count {
                            let b = i * stride
                            guard b + 12 <= r.count else { break }
                            out.append(SIMD3(
                                r.load(fromByteOffset: b,     as: Float.self),
                                r.load(fromByteOffset: b + 4, as: Float.self),
                                r.load(fromByteOffset: b + 8, as: Float.self)))
                        }
                    }
                    return out
                }

                func vec2Array(_ bytes: Data, _ count: Int, _ stride: Int) -> [SIMD2<Float>] {
                    var out = [SIMD2<Float>]()
                    out.reserveCapacity(count)
                    bytes.withUnsafeBytes { r in
                        for i in 0..<count {
                            let b = i * stride
                            guard b + 8 <= r.count else { break }
                            out.append(SIMD2(
                                r.load(fromByteOffset: b,     as: Float.self),
                                r.load(fromByteOffset: b + 4, as: Float.self)))
                        }
                    }
                    return out
                }

                let positions = vec3Array(posBytes, vertCount, posStride)

                var normals = [SIMD3<Float>]()
                if let nIdx = attrs["NORMAL"],
                   let (nB, nC, nS, _) = accessorData(nIdx) {
                    normals = vec3Array(nB, nC, nS)
                }

                var uvs = [SIMD2<Float>]()
                if let uIdx = attrs["TEXCOORD_0"],
                   let (uB, uC, uS, _) = accessorData(uIdx) {
                    uvs = vec2Array(uB, uC, uS)
                }

                // ── Indices ──────────────────────────────────────────────────
                var indices = [UInt32]()
                if let iAccIdx = prim["indices"] as? Int,
                   let (iBytes, iCount, _, iComp) = accessorData(iAccIdx) {
                    indices.reserveCapacity(iCount)
                    iBytes.withUnsafeBytes { r in
                        switch iComp {
                        case 5121:  // UNSIGNED_BYTE
                            for i in 0..<iCount { indices.append(UInt32(r[i])) }
                        case 5123:  // UNSIGNED_SHORT
                            for i in 0..<iCount {
                                let off = i * 2
                                guard off + 2 <= r.count else { break }
                                indices.append(UInt32(r.load(fromByteOffset: off, as: UInt16.self)))
                            }
                        case 5125:  // UNSIGNED_INT
                            for i in 0..<iCount {
                                let off = i * 4
                                guard off + 4 <= r.count else { break }
                                indices.append(r.load(fromByteOffset: off, as: UInt32.self))
                            }
                        default: break
                        }
                    }
                }

                guard !indices.isEmpty else {
                    print("[GLBAssetLoader] parseGLB('\(label)'): m\(mi)p\(pi) ❌ no indices")
                    continue
                }

                // Trim to triangle boundary
                let trimmedIndices = Array(indices.prefix(indices.count - indices.count % 3))

                // ── MeshDescriptor → ModelEntity ─────────────────────────────
                var desc = MeshDescriptor(name: mesh["name"] as? String ?? label)
                desc.positions = MeshBuffer(positions)
                if normals.count == positions.count { desc.normals             = MeshBuffer(normals) }
                if uvs.count     == positions.count { desc.textureCoordinates  = MeshBuffer(uvs) }
                desc.primitives = .triangles(trimmedIndices)

                do {
                    let meshRes = try MeshResource.generate(from: [desc])
                    let matIdx  = prim["material"] as? Int
                    let model   = ModelEntity(mesh: meshRes, materials: [buildMaterial(matIdx)])
                    model.name  = desc.name
                    root.addChild(model)
                    meshCount += 1
                    print("[GLBAssetLoader] parseGLB('\(label)'): m\(mi)p\(pi) ✅ \(positions.count)v \(trimmedIndices.count / 3)t")
                } catch {
                    print("[GLBAssetLoader] parseGLB('\(label)'): m\(mi)p\(pi) ❌ MeshResource: \(error)")
                }
            }
        }

        print("[GLBAssetLoader] parseGLB('\(label)'): \(meshCount) model entity/entities built")
        return meshCount > 0 ? root : nil
    }
}

// MARK: - Data helpers

private extension Data {
    /// Loads a little-endian UInt32 at the given byte offset (GLB is always LE).
    func gltfU32(at offset: Int) -> UInt32 {
        withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }
    }
}
