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

// MARK: - Compact Map Avatar (perpendicular to map ground plane, compass-oriented)

struct Avatar3DMapView: UIViewRepresentable {
    let config: AvatarConfig
    var isWalking: Bool = false
    /// Device compass heading in radians (0 = north, clockwise).
    /// The avatar always faces the compass direction, regardless of map rotation.
    var compassHeading: Float = 0
    /// Current map camera heading in degrees (0 = north). Used to offset
    /// the avatar's Y-rotation so it stays locked to compass north when the map rotates.
    var mapHeading: Double = 0
    /// Current map camera pitch in degrees (0 = top-down, ~60 = tilted perspective).
    /// At 0 pitch (top-down) the SceneKit camera looks straight down at the avatar's head.
    /// As pitch increases, the camera orbits to show the full body.
    var cameraPitch: Double = 0
    /// Emote to play on the avatar, if any.
    var emote: EmoteType?

    /// Camera node name for lookup.
    private static let cameraNodeName = "avatarCamera"

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

        // Camera — orbits the avatar based on map pitch
        let cameraNode = SCNNode()
        cameraNode.name = Self.cameraNodeName
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 1.2
        cameraNode.camera = camera
        scene.rootNode.addChildNode(cameraNode)

        // Position camera based on initial pitch
        updateCameraForPitch(cameraNode: cameraNode, pitch: cameraPitch)

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
        context.coordinator.currentCompassHeading = compassHeading
        context.coordinator.currentEmote = emote
        context.coordinator.currentCameraPitch = cameraPitch

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

        // Update facing whenever compass or map rotation changes
        if coord.currentMapHeading != mapHeading || coord.currentCompassHeading != compassHeading {
            coord.currentMapHeading = mapHeading
            coord.currentCompassHeading = compassHeading
            if let controller = coord.animationController {
                updateFacing(rootNode: rootNode, controller: controller)
            }
        }

        // Update camera orbit immediately when map pitch changes — no threshold
        // or animation delay so the avatar perspective stays in sync with the map.
        if coord.currentCameraPitch != cameraPitch {
            coord.currentCameraPitch = cameraPitch
            if let cameraNode = scene.rootNode.childNode(withName: Self.cameraNodeName, recursively: false) {
                updateCameraForPitch(cameraNode: cameraNode, pitch: cameraPitch)
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

    /// Orbits the SceneKit camera around the avatar based on map pitch.
    /// pitch=0 → camera directly above (looking down at head)
    /// pitch=60+ → camera in front at eye level (showing full body)
    private func updateCameraForPitch(cameraNode: SCNNode, pitch: Double) {
        // Normalize pitch: map gives 0 (top-down) to ~60-90 (horizon).
        // We map this to a SceneKit camera orbit angle:
        //   0° map pitch → SceneKit camera at 80° above (almost top-down, see head)
        //   60° map pitch → SceneKit camera at 10° above (front-facing, see body)
        let clampedPitch = min(max(pitch, 0), 70)
        let t = clampedPitch / 70.0 // 0 = top-down, 1 = fully tilted

        // Camera orbit: interpolate from top-down to front view
        let orbitRadius: Float = 3.0
        // elevation angle from horizontal: 80° (top) down to 10° (front)
        let elevationDeg = 80.0 - t * 70.0
        let elevationRad = Float(elevationDeg * .pi / 180)

        let camY = Float(0.4) + orbitRadius * sin(elevationRad)
        let camZ = orbitRadius * cos(elevationRad)

        cameraNode.position = SCNVector3(0, camY, camZ)
        cameraNode.look(at: SCNVector3(0, 0.3, 0))
    }

    /// Computes the avatar's Y-rotation so it faces the device compass direction
    /// relative to the current map orientation.
    private func updateFacing(rootNode: SCNNode, controller: AvatarAnimationController) {
        let mapHeadingRad = Float(mapHeading * .pi / 180)
        let adjustedAngle = compassHeading - mapHeadingRad
        controller.setFacingDirection(adjustedAngle)
    }

    final class Coordinator {
        var animationController: AvatarAnimationController?
        var currentIsWalking = false
        var currentMapHeading: Double = 0
        var currentCompassHeading: Float = 0
        var currentCameraPitch: Double = 0
        var currentEmote: EmoteType?
    }
}
