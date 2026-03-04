import SceneKit

/// Controls idle and walking animations on the 3D avatar SceneKit nodes.
/// Animations are driven by SCNAction sequences that can be swapped dynamically.
final class AvatarAnimationController {

    enum AnimationState: Equatable {
        case idle
        case walking
        case emote(EmoteType)
    }

    private weak var rootNode: SCNNode?
    private(set) var currentState: AnimationState = .idle

    /// The Y-axis rotation to face the direction of movement (radians).
    private(set) var facingAngle: Float = 0

    private static let idleKey = "idleAnimation"
    private static let walkKey = "walkAnimation"
    private static let emoteKey = "emoteAnimation"

    /// Optional skeleton animator for rigged GLB models.
    private var skeletonAnimator: AvatarSkeletonAnimator?

    /// State to return to after a one-shot emote finishes.
    private var previousState: AnimationState = .idle

    init(rootNode: SCNNode) {
        self.rootNode = rootNode
        self.skeletonAnimator = AvatarSkeletonAnimator(rootNode: rootNode)
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

    /// Plays a one-shot emote animation, then returns to previous state.
    func playEmote(_ emoteType: EmoteType) {
        previousState = currentState
        currentState = .emote(emoteType)
        stopAllAnimations()

        // Try skeletal animation first
        if let animator = skeletonAnimator, animator.isRigged {
            animator.playAnimation(named: emoteType.rawValue, loop: false)
            // Return to previous state after estimated duration
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.returnFromEmote()
            }
            return
        }

        // Procedural emote animations
        applyProceduralEmote(emoteType)
    }

    func startInitialAnimation() {
        currentState = .idle
        applyIdleAnimation()
    }

    private func returnFromEmote() {
        switch previousState {
        case .idle: playIdle()
        case .walking: playWalking()
        case .emote: playIdle()
        }
    }

    // MARK: - Stop

    private func stopAllAnimations() {
        guard let root = rootNode else { return }
        removeAnimationsRecursive(node: root, keys: [
            Self.idleKey, Self.walkKey, Self.emoteKey,
            "armSwing", "legSwing", "breathe", "bob", "headTilt", "lookAround"
        ])
        skeletonAnimator?.stopAllAnimations()
    }

    private func removeAnimationsRecursive(node: SCNNode, keys: [String]) {
        for key in keys {
            node.removeAction(forKey: key)
        }
        for child in node.childNodes {
            removeAnimationsRecursive(node: child, keys: keys)
        }
    }

    // MARK: - Procedural Emote Animations

    private func applyProceduralEmote(_ emoteType: EmoteType) {
        guard let root = rootNode else { return }

        let duration: TimeInterval
        switch emoteType {
        case .wave:
            duration = 2.0
            if let rightArm = root.childNode(withName: Avatar3DSceneBuilder.NodeName.rightArm, recursively: false) {
                let raise = SCNAction.rotateTo(x: 0, y: 0, z: CGFloat(-Float.pi * 0.75), duration: 0.3)
                let waveLeft = SCNAction.rotateTo(x: 0, y: 0, z: CGFloat(-Float.pi * 0.6), duration: 0.2)
                let waveRight = SCNAction.rotateTo(x: 0, y: 0, z: CGFloat(-Float.pi * 0.85), duration: 0.2)
                let wave = SCNAction.sequence([raise, .repeat(.sequence([waveLeft, waveRight]), count: 3)])
                rightArm.runAction(wave, forKey: Self.emoteKey)
            }

        case .dance:
            duration = 3.0
            let bounceUp = SCNAction.moveBy(x: 0, y: 0.08, z: 0, duration: 0.15)
            bounceUp.timingMode = .easeOut
            let bounceDown = bounceUp.reversed()
            let bounce = SCNAction.repeat(.sequence([bounceUp, bounceDown]), count: 8)
            if let body = root.childNode(withName: Avatar3DSceneBuilder.NodeName.body, recursively: false) {
                body.runAction(bounce, forKey: Self.emoteKey)
            }
            for (name, sign) in [(Avatar3DSceneBuilder.NodeName.leftArm, Float(1)),
                                 (Avatar3DSceneBuilder.NodeName.rightArm, Float(-1))] {
                if let arm = root.childNode(withName: name, recursively: false) {
                    let up = SCNAction.rotateTo(x: CGFloat(-Float.pi * 0.4), y: 0, z: CGFloat(sign * Float.pi * 0.2), duration: 0.3)
                    let down = SCNAction.rotateTo(x: CGFloat(Float.pi * 0.1), y: 0, z: CGFloat(sign * Float.pi * 0.12), duration: 0.3)
                    arm.runAction(.repeat(.sequence([up, down]), count: 5), forKey: Self.emoteKey)
                }
            }

        case .celebrate:
            duration = 2.5
            // Jump + arms up
            let jump = SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.15, z: 0, duration: 0.2),
                SCNAction.moveBy(x: 0, y: -0.15, z: 0, duration: 0.2)
            ])
            root.runAction(.repeat(jump, count: 3), forKey: Self.emoteKey)
            for name in [Avatar3DSceneBuilder.NodeName.leftArm, Avatar3DSceneBuilder.NodeName.rightArm] {
                if let arm = root.childNode(withName: name, recursively: false) {
                    let raiseUp = SCNAction.rotateTo(x: CGFloat(-Float.pi * 0.8), y: 0, z: 0, duration: 0.2)
                    arm.runAction(raiseUp, forKey: Self.emoteKey)
                }
            }

        case .clap:
            duration = 2.0
            for (name, sign) in [(Avatar3DSceneBuilder.NodeName.leftArm, Float(1)),
                                 (Avatar3DSceneBuilder.NodeName.rightArm, Float(-1))] {
                if let arm = root.childNode(withName: name, recursively: false) {
                    let inward = SCNAction.rotateTo(x: CGFloat(-Float.pi * 0.45), y: 0, z: CGFloat(-sign * 0.3), duration: 0.15)
                    let outward = SCNAction.rotateTo(x: CGFloat(-Float.pi * 0.45), y: 0, z: CGFloat(sign * 0.2), duration: 0.15)
                    arm.runAction(.repeat(.sequence([inward, outward]), count: 5), forKey: Self.emoteKey)
                }
            }

        case .flex:
            duration = 2.0
            for (name, sign) in [(Avatar3DSceneBuilder.NodeName.leftArm, Float(1)),
                                 (Avatar3DSceneBuilder.NodeName.rightArm, Float(-1))] {
                if let arm = root.childNode(withName: name, recursively: false) {
                    let flex = SCNAction.rotateTo(x: CGFloat(-Float.pi * 0.5), y: 0, z: CGFloat(sign * Float.pi * 0.3), duration: 0.4)
                    let hold = SCNAction.wait(duration: 1.2)
                    arm.runAction(.sequence([flex, hold]), forKey: Self.emoteKey)
                }
            }

        case .spin:
            duration = 1.5
            let spin = SCNAction.rotateBy(x: 0, y: CGFloat(Float.pi * 2), z: 0, duration: 0.8)
            spin.timingMode = .easeInEaseOut
            root.runAction(spin, forKey: Self.emoteKey)

        case .bow:
            duration = 2.0
            let bowForward = SCNAction.rotateTo(x: CGFloat(Float.pi * 0.25), y: 0, z: 0, duration: 0.5)
            let hold = SCNAction.wait(duration: 1.0)
            let bowBack = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.5)
            root.runAction(.sequence([bowForward, hold, bowBack]), forKey: Self.emoteKey)

        case .shrug:
            duration = 2.0
            for name in [Avatar3DSceneBuilder.NodeName.leftArm, Avatar3DSceneBuilder.NodeName.rightArm] {
                if let arm = root.childNode(withName: name, recursively: false) {
                    let shrug = SCNAction.rotateTo(x: 0, y: 0, z: CGFloat(-Float.pi * 0.35), duration: 0.3)
                    let hold = SCNAction.wait(duration: 1.2)
                    let back = SCNAction.rotateTo(x: 0, y: 0, z: CGFloat(arm.eulerAngles.z), duration: 0.3)
                    arm.runAction(.sequence([shrug, hold, back]), forKey: Self.emoteKey)
                }
            }
            // Head tilt
            if let head = root.childNode(withName: Avatar3DSceneBuilder.NodeName.head, recursively: false) {
                let tilt = SCNAction.rotateTo(x: 0, y: 0, z: 0.15, duration: 0.3)
                let back = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.3)
                head.runAction(.sequence([tilt, .wait(duration: 1.2), back]), forKey: Self.emoteKey)
            }
        }

        // Return to previous state after emote finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.returnFromEmote()
        }
    }

    // MARK: - Idle Animation

    /// Rich idle: breathing Y-scale, weight shifting (X-sway), head looking
    /// around (random Y-rotation), occasional fidgets, and subtle arm sway.
    private func applyIdleAnimation() {
        guard let root = rootNode else { return }

        // Body breathing (Y-scale pulse) + gentle bob
        if let body = root.childNode(withName: Avatar3DSceneBuilder.NodeName.body, recursively: false) {
            let bobUp = SCNAction.moveBy(x: 0, y: 0.03, z: 0, duration: 1.2)
            bobUp.timingMode = .easeInEaseOut
            let bobDown = bobUp.reversed()
            let bob = SCNAction.repeatForever(.sequence([bobUp, bobDown]))
            body.runAction(bob, forKey: "breathe")

            // Breathing Y-scale
            let breatheIn = SCNAction.customAction(duration: 1.4) { node, elapsed in
                let t = Float(elapsed / 1.4)
                let scale = 1.0 + sin(t * Float.pi) * 0.015
                node.scale = SCNVector3(node.scale.x, scale, node.scale.z)
            }
            let breatheOut = SCNAction.customAction(duration: 1.4) { node, elapsed in
                let t = Float(elapsed / 1.4)
                let scale = 1.015 - sin(t * Float.pi) * 0.015
                node.scale = SCNVector3(node.scale.x, scale, node.scale.z)
            }
            body.runAction(.repeatForever(.sequence([breatheIn, breatheOut])), forKey: "bob")
        }

        // Weight shifting (X-sway on root)
        let swayLeft = SCNAction.moveBy(x: 0.015, y: 0, z: 0, duration: 2.5)
        swayLeft.timingMode = .easeInEaseOut
        let swayRight = SCNAction.moveBy(x: -0.03, y: 0, z: 0, duration: 5.0)
        swayRight.timingMode = .easeInEaseOut
        let swayCenter = SCNAction.moveBy(x: 0.015, y: 0, z: 0, duration: 2.5)
        swayCenter.timingMode = .easeInEaseOut
        root.runAction(.repeatForever(.sequence([swayLeft, swayRight, swayCenter])), forKey: "bob")

        // Head: gentle tilt + random Y-rotation look-around
        if let head = root.childNode(withName: Avatar3DSceneBuilder.NodeName.head, recursively: false) {
            let headBobUp = SCNAction.moveBy(x: 0, y: 0.04, z: 0, duration: 1.2)
            headBobUp.timingMode = .easeInEaseOut
            let headBobDown = headBobUp.reversed()
            headBobDown.timingMode = .easeInEaseOut
            let headBob = SCNAction.repeatForever(.sequence([headBobUp, headBobDown]))
            head.runAction(headBob, forKey: "breathe")

            let tiltLeft = SCNAction.rotateTo(x: 0, y: 0, z: 0.06, duration: 2.0, usesShortestUnitArc: true)
            tiltLeft.timingMode = .easeInEaseOut
            let tiltRight = SCNAction.rotateTo(x: 0, y: 0, z: -0.06, duration: 2.0, usesShortestUnitArc: true)
            tiltRight.timingMode = .easeInEaseOut
            let tiltCenter = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 2.0, usesShortestUnitArc: true)
            tiltCenter.timingMode = .easeInEaseOut
            let headTilt = SCNAction.repeatForever(.sequence([tiltLeft, tiltCenter, tiltRight, tiltCenter]))
            head.runAction(headTilt, forKey: "headTilt")

            // Random Y-rotation look-around
            let lookAround = SCNAction.repeatForever(SCNAction.sequence([
                SCNAction.wait(duration: 3.0, withRange: 4.0),
                SCNAction.rotateTo(
                    x: 0,
                    y: CGFloat(Float.random(in: -0.3...0.3)),
                    z: CGFloat(head.eulerAngles.z),
                    duration: 0.8,
                    usesShortestUnitArc: true
                ),
                SCNAction.wait(duration: 2.0, withRange: 2.0),
                SCNAction.rotateTo(x: 0, y: 0, z: CGFloat(head.eulerAngles.z), duration: 0.6, usesShortestUnitArc: true)
            ]))
            head.runAction(lookAround, forKey: "lookAround")
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
