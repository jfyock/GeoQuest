import SceneKit

/// Wrapper for loading `.glb` files and converting them to `SCNNode` hierarchies.
/// Uses GLTFKit2 when available, with caching for loaded models.
enum GLBModelLoader {

    /// In-memory cache of loaded model nodes keyed by file name.
    private static var cache: [String: SCNNode] = [:]

    /// Attempts to load a `.glb` model from the app bundle.
    /// - Parameters:
    ///   - name: The file name without extension (e.g. "avatar_body").
    ///   - subdirectory: Optional subdirectory within the bundle.
    ///   - validateRig: If true, checks for required bone names from `AvatarRigDefinition`.
    /// - Returns: A cloned `SCNNode` from the loaded scene, or nil if the file is not found.
    static func loadGLB(named name: String, subdirectory: String? = nil, validateRig: Bool = false) -> SCNNode? {
        // Check cache first
        let cacheKey = "\(subdirectory ?? "")/\(name)"
        if let cached = cache[cacheKey] {
            return cached.clone()
        }

        let directories: [String?] = [subdirectory, "Models", "Resources/Models", nil]

        for dir in directories {
            guard let url = Bundle.main.url(forResource: name, withExtension: "glb", subdirectory: dir) else {
                continue
            }

            do {
                // Try loading via GLTFKit2 if available
                if let node = try loadViaGLTFKit2(url: url) {
                    if validateRig {
                        let foundBones = collectNodeNames(node)
                        let missing = AvatarRigDefinition.requiredBones.subtracting(foundBones)
                        if !missing.isEmpty {
                            print("[GLBModelLoader] Model '\(name)' missing required bones: \(missing)")
                        }
                    }
                    cache[cacheKey] = node
                    return node.clone()
                }
            } catch {
                print("[GLBModelLoader] Failed to load '\(name).glb': \(error)")
            }
        }

        return nil
    }

    /// Loads a skin variant GLB model.
    /// Convention: `avatar_body_<skinId>.glb`
    static func loadSkinModel(skinId: String) -> SCNNode? {
        return loadGLB(named: "avatar_body_\(skinId)", subdirectory: "Skins", validateRig: true)
    }

    /// Loads an accessory GLB model.
    /// Convention: `accessory_<name>.glb`
    static func loadAccessoryGLB(named name: String) -> SCNNode? {
        return loadGLB(named: "accessory_\(name)", subdirectory: "Accessories")
    }

    /// Clears the model cache. Call when receiving a memory warning.
    static func clearCache() {
        cache.removeAll()
    }

    // MARK: - Private

    /// Attempts to load a GLB file using GLTFKit2's SCNScene conversion.
    /// Returns nil if GLTFKit2 is not linked.
    private static func loadViaGLTFKit2(url: URL) throws -> SCNNode? {
        // Dynamic lookup: try to use GLTFKit2 if it's been added to the project.
        // This avoids a hard dependency at compile time.
        guard let sceneSourceClass = NSClassFromString("GLTFSCNSceneSource") as? NSObject.Type else {
            // GLTFKit2 is not available — try SCNScene as a last resort
            let scene = try SCNScene(url: url, options: [.checkConsistency: true])
            return wrapSceneNodes(scene)
        }

        // Use GLTFKit2: GLTFSCNSceneSource(url:options:)
        let sceneSource = sceneSourceClass.init()
        let selector = NSSelectorFromString("initWithURL:options:")
        if sceneSource.responds(to: selector) {
            _ = sceneSource.perform(selector, with: url, with: nil)
        }

        // Get the default scene
        let sceneSelector = NSSelectorFromString("defaultScene")
        if sceneSource.responds(to: sceneSelector),
           let scene = sceneSource.perform(sceneSelector)?.takeUnretainedValue() as? SCNScene {
            return wrapSceneNodes(scene)
        }

        return nil
    }

    private static func wrapSceneNodes(_ scene: SCNScene) -> SCNNode {
        let container = SCNNode()
        for child in scene.rootNode.childNodes {
            container.addChildNode(child)
        }
        return container
    }

    /// Recursively collects all node names in a hierarchy.
    private static func collectNodeNames(_ node: SCNNode) -> Set<String> {
        var names: Set<String> = []
        if let name = node.name {
            names.insert(name)
        }
        for child in node.childNodes {
            names.formUnion(collectNodeNames(child))
        }
        return names
    }
}
