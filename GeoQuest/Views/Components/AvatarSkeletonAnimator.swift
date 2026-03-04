import SceneKit

/// Handles skeletal animation for rigged GLB models.
/// Falls back to procedural `AvatarAnimationController` when no skeleton is found.
final class AvatarSkeletonAnimator {

    private weak var rootNode: SCNNode?
    private let hasRig: Bool

    init(rootNode: SCNNode) {
        self.rootNode = rootNode
        // Detect rig by looking for required bone names
        self.hasRig = Self.detectRig(in: rootNode)
    }

    /// Whether a skeletal rig was detected.
    var isRigged: Bool { hasRig }

    /// Plays a named animation clip from the bundle (e.g. "dance", "wave").
    /// - Parameters:
    ///   - name: Animation clip name (file must be `<name>.glb` or `<name>.scn` in the bundle).
    ///   - loop: Whether to loop the animation.
    ///   - crossFadeDuration: Duration for blending between animations.
    func playAnimation(named name: String, loop: Bool = false, crossFadeDuration: TimeInterval = 0.25) {
        guard let root = rootNode, hasRig else { return }

        // Try loading animation from bundle
        let extensions = ["glb", "scn", "dae"]
        let directories: [String?] = ["Animations", "Resources/Animations", nil]

        for dir in directories {
            for ext in extensions {
                if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: dir) {
                    do {
                        let scene = try SCNScene(url: url, options: [.checkConsistency: true])
                        for animKey in scene.rootNode.animationKeys {
                            if let player = scene.rootNode.animationPlayer(forKey: animKey) {
                                player.animation.isRemovedOnCompletion = !loop
                                player.animation.repeatCount = loop ? .infinity : 1
                                player.animation.fadeInDuration = crossFadeDuration
                                player.animation.fadeOutDuration = crossFadeDuration
                                root.addAnimationPlayer(player, forKey: name)
                                player.play()
                                return
                            }
                        }
                    } catch {
                        print("[AvatarSkeletonAnimator] Failed to load animation '\(name)': \(error)")
                    }
                }
            }
        }
    }

    /// Stops a playing animation by key.
    func stopAnimation(named name: String, fadeOutDuration: TimeInterval = 0.25) {
        guard let root = rootNode else { return }
        if let player = root.animationPlayer(forKey: name) {
            player.stop(withBlendOutDuration: fadeOutDuration)
        }
    }

    /// Stops all skeletal animations.
    func stopAllAnimations() {
        guard let root = rootNode else { return }
        for key in root.animationKeys {
            root.removeAnimation(forKey: key)
        }
    }

    // MARK: - Rig Detection

    private static func detectRig(in node: SCNNode) -> Bool {
        // Check for skinner (skeletal mesh)
        if node.skinner != nil { return true }

        // Check for required bone names
        var foundBones: Set<String> = []
        collectBoneNames(node, into: &foundBones)
        let matches = foundBones.intersection(AvatarRigDefinition.requiredBones)
        return matches.count >= 4 // At least 4 required bones present

    }

    private static func collectBoneNames(_ node: SCNNode, into names: inout Set<String>) {
        if let name = node.name {
            names.insert(name)
        }
        for child in node.childNodes {
            collectBoneNames(child, into: &names)
        }
    }
}
