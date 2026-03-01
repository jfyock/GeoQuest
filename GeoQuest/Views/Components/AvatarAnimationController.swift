import SceneKit

/// Controls idle and walking animations on the 3D avatar SceneKit nodes.
/// Animations are driven by SCNAction sequences that can be swapped dynamically.
final class AvatarAnimationController {

    enum AnimationState: Equatable {
        case idle
        case walking
    }

    private weak var rootNode: SCNNode?
    private(set) var currentState: AnimationState = .idle

    /// The Y-axis rotation to face the direction of movement (radians).
    private(set) var facingAngle: Float = 0

    private static let idleKey = "idleAnimation"
    private static let walkKey = "walkAnimation"

    init(rootNode: SCNNode) {
        self.rootNode = rootNode
    }

    // MARK: - Public API

    func playIdle() {
        guard currentState != .idle else { return }
        currentState = .idle
        stopAllAnimations()
        applyIdleAnimation()
    }

    func playWalking() {
        guard currentState != .walking else { return }
        currentState = .walking
        stopAllAnimations()
        applyWalkingAnimation()
    }

    /// Smoothly rotates the character to face the given angle (radians, 0 = north/+Z).
    func setFacingDirection(_ angle: Float) {
        guard let root = rootNode else { return }
        facingAngle = angle
        let rotate = SCNAction.rotateTo(
            x: CGFloat(root.eulerAngles.x),
            y: CGFloat(angle),
            z: CGFloat(root.eulerAngles.z),
            duration: 0.3,
            usesShortestUnitArc: true
        )
        rotate.timingMode = .easeInEaseOut
        root.runAction(rotate, forKey: "facing")
    }

    func startInitialAnimation() {
        currentState = .idle
        applyIdleAnimation()
    }

    // MARK: - Stop

    private func stopAllAnimations() {
        guard let root = rootNode else { return }
        removeAnimationsRecursive(node: root, keys: [
            Self.idleKey, Self.walkKey,
            "armSwing", "legSwing", "breathe", "bob", "headTilt"
        ])
    }

    private func removeAnimationsRecursive(node: SCNNode, keys: [String]) {
        for key in keys {
            node.removeAction(forKey: key)
        }
        for child in node.childNodes {
            removeAnimationsRecursive(node: child, keys: keys)
        }
    }

    // MARK: - Idle Animation

    /// Subtle breathing / bobbing + slight head sway
    private func applyIdleAnimation() {
        guard let root = rootNode else { return }

        // Body gentle bob
        if let body = root.childNode(withName: Avatar3DSceneBuilder.NodeName.body, recursively: false) {
            let bobUp = SCNAction.moveBy(x: 0, y: 0.03, z: 0, duration: 1.2)
            bobUp.timingMode = .easeInEaseOut
            let bobDown = bobUp.reversed()
            let bob = SCNAction.repeatForever(.sequence([bobUp, bobDown]))
            body.runAction(bob, forKey: "breathe")
        }

        // Head gentle tilt
        if let head = root.childNode(withName: Avatar3DSceneBuilder.NodeName.head, recursively: false) {
            let headBobUp = SCNAction.moveBy(x: 0, y: 0.04, z: 0, duration: 1.2)
            headBobUp.timingMode = .easeInEaseOut
            let headBobDown = headBobUp.reversed()
            headBobDown.timingMode = .easeInEaseOut

            let tiltLeft = SCNAction.rotateTo(x: 0, y: 0, z: 0.06, duration: 2.0, usesShortestUnitArc: true)
            tiltLeft.timingMode = .easeInEaseOut
            let tiltRight = SCNAction.rotateTo(x: 0, y: 0, z: -0.06, duration: 2.0, usesShortestUnitArc: true)
            tiltRight.timingMode = .easeInEaseOut
            let tiltCenter = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 2.0, usesShortestUnitArc: true)
            tiltCenter.timingMode = .easeInEaseOut

            let headBob = SCNAction.repeatForever(.sequence([headBobUp, headBobDown]))
            let headTilt = SCNAction.repeatForever(.sequence([tiltLeft, tiltCenter, tiltRight, tiltCenter]))

            head.runAction(headBob, forKey: "breathe")
            head.runAction(headTilt, forKey: "headTilt")
        }

        // Arms slight sway
        for (name, sign) in [(Avatar3DSceneBuilder.NodeName.leftArm, Float(1)),
                             (Avatar3DSceneBuilder.NodeName.rightArm, Float(-1))] {
            if let arm = root.childNode(withName: name, recursively: false) {
                let baseZ = arm.eulerAngles.z
                let swayOut = SCNAction.rotateTo(
                    x: CGFloat(arm.eulerAngles.x),
                    y: CGFloat(arm.eulerAngles.y),
                    z: CGFloat(baseZ + sign * 0.05),
                    duration: 1.5,
                    usesShortestUnitArc: true
                )
                swayOut.timingMode = .easeInEaseOut
                let swayBack = SCNAction.rotateTo(
                    x: CGFloat(arm.eulerAngles.x),
                    y: CGFloat(arm.eulerAngles.y),
                    z: CGFloat(baseZ - sign * 0.03),
                    duration: 1.5,
                    usesShortestUnitArc: true
                )
                swayBack.timingMode = .easeInEaseOut
                arm.runAction(.repeatForever(.sequence([swayOut, swayBack])), forKey: "armSwing")
            }
        }
    }

    // MARK: - Walking Animation

    /// Arm and leg swinging + body bounce for walking
    private func applyWalkingAnimation() {
        guard let root = rootNode else { return }

        let walkCycleDuration: TimeInterval = 0.4

        // Body bounce
        if let body = root.childNode(withName: Avatar3DSceneBuilder.NodeName.body, recursively: false) {
            let bounceUp = SCNAction.moveBy(x: 0, y: 0.04, z: 0, duration: walkCycleDuration / 2)
            bounceUp.timingMode = .easeOut
            let bounceDown = bounceUp.reversed()
            bounceDown.timingMode = .easeIn
            body.runAction(.repeatForever(.sequence([bounceUp, bounceDown])), forKey: "breathe")
        }

        // Head bounce (smaller)
        if let head = root.childNode(withName: Avatar3DSceneBuilder.NodeName.head, recursively: false) {
            let up = SCNAction.moveBy(x: 0, y: 0.05, z: 0, duration: walkCycleDuration / 2)
            up.timingMode = .easeOut
            let down = up.reversed()
            down.timingMode = .easeIn
            head.runAction(.repeatForever(.sequence([up, down])), forKey: "breathe")
        }

        // Arm swinging (opposite to legs)
        let armSwingAngle: Float = 0.6
        if let leftArm = root.childNode(withName: Avatar3DSceneBuilder.NodeName.leftArm, recursively: false) {
            let baseZ = leftArm.eulerAngles.z
            let forward = SCNAction.rotateTo(
                x: CGFloat(-armSwingAngle), y: 0, z: CGFloat(baseZ),
                duration: walkCycleDuration, usesShortestUnitArc: true
            )
            forward.timingMode = .easeInEaseOut
            let backward = SCNAction.rotateTo(
                x: CGFloat(armSwingAngle), y: 0, z: CGFloat(baseZ),
                duration: walkCycleDuration, usesShortestUnitArc: true
            )
            backward.timingMode = .easeInEaseOut
            leftArm.runAction(.repeatForever(.sequence([forward, backward])), forKey: "armSwing")
        }
        if let rightArm = root.childNode(withName: Avatar3DSceneBuilder.NodeName.rightArm, recursively: false) {
            let baseZ = rightArm.eulerAngles.z
            let backward = SCNAction.rotateTo(
                x: CGFloat(armSwingAngle), y: 0, z: CGFloat(baseZ),
                duration: walkCycleDuration, usesShortestUnitArc: true
            )
            backward.timingMode = .easeInEaseOut
            let forward = SCNAction.rotateTo(
                x: CGFloat(-armSwingAngle), y: 0, z: CGFloat(baseZ),
                duration: walkCycleDuration, usesShortestUnitArc: true
            )
            forward.timingMode = .easeInEaseOut
            rightArm.runAction(.repeatForever(.sequence([backward, forward])), forKey: "armSwing")
        }

        // Leg swinging
        let legSwingAngle: Float = 0.5
        if let leftLeg = root.childNode(withName: Avatar3DSceneBuilder.NodeName.leftLeg, recursively: false) {
            let forward = SCNAction.rotateTo(
                x: CGFloat(-legSwingAngle), y: 0, z: 0,
                duration: walkCycleDuration, usesShortestUnitArc: true
            )
            forward.timingMode = .easeInEaseOut
            let backward = SCNAction.rotateTo(
                x: CGFloat(legSwingAngle), y: 0, z: 0,
                duration: walkCycleDuration, usesShortestUnitArc: true
            )
            backward.timingMode = .easeInEaseOut
            leftLeg.runAction(.repeatForever(.sequence([forward, backward])), forKey: "legSwing")
        }
        if let rightLeg = root.childNode(withName: Avatar3DSceneBuilder.NodeName.rightLeg, recursively: false) {
            let backward = SCNAction.rotateTo(
                x: CGFloat(legSwingAngle), y: 0, z: 0,
                duration: walkCycleDuration, usesShortestUnitArc: true
            )
            backward.timingMode = .easeInEaseOut
            let forward = SCNAction.rotateTo(
                x: CGFloat(-legSwingAngle), y: 0, z: 0,
                duration: walkCycleDuration, usesShortestUnitArc: true
            )
            forward.timingMode = .easeInEaseOut
            rightLeg.runAction(.repeatForever(.sequence([backward, forward])), forKey: "legSwing")
        }
    }
}
