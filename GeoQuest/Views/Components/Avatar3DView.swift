import SceneKit
import SwiftUI

/// A reusable 3D avatar view rendered via SceneKit.
/// Supports interactive rotation (swipe to spin), idle/walking animation, and dynamic config updates.
struct Avatar3DView: UIViewRepresentable {
    let config: AvatarConfig
    var size: CGFloat = 200
    /// Whether the user can drag to rotate the avatar.
    var allowsInteractiveRotation: Bool = false
    /// Whether to show walking animation (vs idle).
    var isWalking: Bool = false
    /// Heading direction in radians for facing (0 = towards camera).
    var facingAngle: Float = 0
    /// Whether to render with a transparent background (for map overlay).
    var transparentBackground: Bool = false

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.autoenablesDefaultLighting = false
        scnView.antialiasingMode = .multisampling4X
        scnView.isJitteringEnabled = true

        // Build scene
        let scene = Avatar3DSceneBuilder.buildScene(config: config, size: size)
        scnView.scene = scene

        // Camera
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.fieldOfView = 30
        camera.usesOrthographicProjection = false
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0.3, 4.5)
        cameraNode.look(at: SCNVector3(0, 0.1, 0))
        scene.rootNode.addChildNode(cameraNode)

        // Start animation
        if let rootNode = scene.rootNode.childNode(withName: Avatar3DSceneBuilder.NodeName.root, recursively: false) {
            let controller = AvatarAnimationController(rootNode: rootNode)
            if isWalking {
                controller.playWalking()
                controller.setFacingDirection(facingAngle)
            } else {
                controller.startInitialAnimation()
            }
            context.coordinator.animationController = controller
        }

        // Interactive rotation gesture
        if allowsInteractiveRotation {
            let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
            scnView.addGestureRecognizer(pan)
            context.coordinator.scnView = scnView
        }

        // Disable built-in camera control (we do manual rotation)
        scnView.allowsCameraControl = false

        context.coordinator.currentConfig = config
        context.coordinator.currentIsWalking = isWalking

        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        let coord = context.coordinator

        // Rebuild scene if config changed
        if coord.currentConfig != config {
            coord.currentConfig = config
            rebuildScene(scnView: scnView, context: context)
        }

        // Switch animation if walking state changed
        if coord.currentIsWalking != isWalking {
            coord.currentIsWalking = isWalking
            if isWalking {
                coord.animationController?.playWalking()
            } else {
                coord.animationController?.playIdle()
            }
        }

        // Update facing direction
        if isWalking {
            coord.animationController?.setFacingDirection(facingAngle)
        }
    }

    private func rebuildScene(scnView: SCNView, context: Context) {
        guard let scene = scnView.scene else { return }

        // Remove old avatar
        scene.rootNode.childNode(withName: Avatar3DSceneBuilder.NodeName.root, recursively: false)?.removeFromParentNode()

        // Build new
        let rootNode = Avatar3DSceneBuilder.buildCharacter(config: config, scale: size / 200.0)

        // Preserve rotation from interactive pan
        if allowsInteractiveRotation {
            rootNode.eulerAngles.y = context.coordinator.currentYRotation
        }

        scene.rootNode.addChildNode(rootNode)

        // Re-setup animation
        let controller = AvatarAnimationController(rootNode: rootNode)
        if isWalking {
            controller.playWalking()
            controller.setFacingDirection(facingAngle)
        } else {
            controller.startInitialAnimation()
        }
        context.coordinator.animationController = controller
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject {
        var animationController: AvatarAnimationController?
        var currentConfig: AvatarConfig?
        var currentIsWalking: Bool = false
        var currentYRotation: Float = 0
        weak var scnView: SCNView?

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let scnView = scnView,
                  let scene = scnView.scene,
                  let rootNode = scene.rootNode.childNode(
                      withName: Avatar3DSceneBuilder.NodeName.root, recursively: false
                  ) else { return }

            let translation = gesture.translation(in: scnView)
            let rotationSpeed: Float = 0.01

            rootNode.eulerAngles.y += Float(translation.x) * rotationSpeed
            currentYRotation = rootNode.eulerAngles.y

            gesture.setTranslation(.zero, in: scnView)

            // Add momentum on release
            if gesture.state == .ended {
                let velocity = gesture.velocity(in: scnView)
                let momentumRotation = Float(velocity.x) * rotationSpeed * 0.15
                let spinAction = SCNAction.rotateBy(
                    x: 0,
                    y: CGFloat(momentumRotation),
                    z: 0,
                    duration: 0.5
                )
                spinAction.timingMode = .easeOut
                rootNode.runAction(spinAction) { [weak self] in
                    self?.currentYRotation = rootNode.eulerAngles.y
                }
            }
        }
    }
}

// MARK: - Compact Map Avatar (isometric, oriented to map ground plane)

struct Avatar3DMapView: UIViewRepresentable {
    let config: AvatarConfig
    var isWalking: Bool = false
    var facingAngle: Float = 0
    /// Current map camera heading in degrees (0 = north). Used to keep the avatar
    /// oriented correctly when the user rotates the map.
    var mapHeading: Double = 0
    /// Emote to play on the avatar, if any.
    var emote: EmoteType?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.autoenablesDefaultLighting = false
        scnView.antialiasingMode = .multisampling4X
        scnView.preferredFramesPerSecond = 30 // save battery on map
        // Render at high resolution so the avatar stays sharp when scaled up
        scnView.contentScaleFactor = UIScreen.main.scale * 2

        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        let rootNode = Avatar3DSceneBuilder.buildCharacter(config: config, scale: 0.35)
        rootNode.name = Avatar3DSceneBuilder.NodeName.root
        scene.rootNode.addChildNode(rootNode)

        Avatar3DSceneBuilder.addLightingPublic(to: scene)

        // Isometric-style camera: angled from above so avatar appears upright on the map ground
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.fieldOfView = 28
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 1.2
        cameraNode.camera = camera
        // Position above and in front, looking down at ~55 degrees
        cameraNode.position = SCNVector3(0, 1.8, 1.5)
        cameraNode.look(at: SCNVector3(0, 0.1, 0))
        scene.rootNode.addChildNode(cameraNode)

        scnView.scene = scene

        let controller = AvatarAnimationController(rootNode: rootNode)
        if isWalking {
            controller.playWalking()
        } else {
            controller.startInitialAnimation()
        }
        // Apply initial facing with map heading offset
        updateFacing(rootNode: rootNode, controller: controller)

        context.coordinator.animationController = controller
        context.coordinator.currentIsWalking = isWalking
        context.coordinator.currentMapHeading = mapHeading
        context.coordinator.currentFacingAngle = facingAngle
        context.coordinator.currentEmote = emote

        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        let coord = context.coordinator
        guard let scene = scnView.scene,
              let rootNode = scene.rootNode.childNode(
                  withName: Avatar3DSceneBuilder.NodeName.root, recursively: false
              ) else { return }

        if coord.currentIsWalking != isWalking {
            coord.currentIsWalking = isWalking
            if isWalking {
                coord.animationController?.playWalking()
            } else {
                coord.animationController?.playIdle()
            }
        }

        // Update facing whenever heading or map rotation changes
        if coord.currentMapHeading != mapHeading || coord.currentFacingAngle != facingAngle {
            coord.currentMapHeading = mapHeading
            coord.currentFacingAngle = facingAngle
            if let controller = coord.animationController {
                updateFacing(rootNode: rootNode, controller: controller)
            }
        }

        // Play emote if changed
        if coord.currentEmote != emote {
            coord.currentEmote = emote
            if let emote {
                coord.animationController?.playEmote(emote)
            }
        }
    }

    /// Computes the avatar's Y-rotation so it faces its movement direction
    /// relative to the current map orientation.
    private func updateFacing(rootNode: SCNNode, controller: AvatarAnimationController) {
        // Convert map heading from degrees to radians and offset the facing angle
        let mapHeadingRad = Float(mapHeading * .pi / 180)
        let adjustedAngle = facingAngle - mapHeadingRad
        controller.setFacingDirection(adjustedAngle)
    }

    final class Coordinator {
        var animationController: AvatarAnimationController?
        var currentIsWalking = false
        var currentMapHeading: Double = 0
        var currentFacingAngle: Float = 0
        var currentEmote: EmoteType?
    }
}
