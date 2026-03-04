import SceneKit
import SwiftUI

/// Builds a SceneKit scene containing the 3D avatar character with proper body proportions.
/// The character is a cartoony figure with a spherical head, capsule body, arms, and legs.
/// Accessories are attached to anatomically correct anchor nodes.
/// Supports loading custom USDZ models from the app bundle with procedural fallback.
enum Avatar3DSceneBuilder {

    // MARK: - Node Names (used for lookups)
    enum NodeName {
        static let root = "avatarRoot"
        static let body = "body"
        static let head = "head"
        static let leftEye = "leftEye"
        static let rightEye = "rightEye"
        static let mouth = "mouth"
        static let leftArm = "leftArm"
        static let rightArm = "rightArm"
        static let leftLeg = "leftLeg"
        static let rightLeg = "rightLeg"
        static let accessoryAnchor = "accessoryAnchor"
        static let hatAnchor = "hatAnchor"
        static let glassesAnchor = "glassesAnchor"
        static let accessory = "accessory"
    }

    // MARK: - USDZ Model Loading

    /// Attempts to load a USDZ or SCN model from the app bundle by name.
    /// Searches in the bundle root and a "Models" subdirectory.
    /// Returns nil if no matching file is found (caller should fall back to procedural geometry).
    static func loadModel(named name: String) -> SCNNode? {
        // Try GLB via GLBModelLoader first
        if let glbNode = GLBModelLoader.loadGLB(named: name) {
            return glbNode
        }

        // Fall back to USDZ/SCN/DAE
        let extensions = ["usdz", "scn", "dae"]
        let directories: [String?] = [nil, "Models", "Resources/Models"]

        for dir in directories {
            for ext in extensions {
                if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: dir) {
                    do {
                        let scene = try SCNScene(url: url, options: [
                            .checkConsistency: true
                        ])
                        let container = SCNNode()
                        for child in scene.rootNode.childNodes {
                            container.addChildNode(child)
                        }
                        return container
                    } catch {
                        print("[Avatar3D] Failed to load model '\(name).\(ext)': \(error)")
                    }
                }
            }
        }
        return nil
    }

    /// Applies the avatar body color to all materials on a loaded model node.
    static func applyBodyColor(_ color: AvatarBodyColor, to node: SCNNode) {
        let uiCol = uiColor(for: color)
        applyColorRecursive(uiCol, to: node)
    }

    private static func applyColorRecursive(_ color: UIColor, to node: SCNNode) {
        if let geometry = node.geometry {
            for material in geometry.materials {
                material.diffuse.contents = color
            }
        }
        for child in node.childNodes {
            applyColorRecursive(color, to: child)
        }
    }

    /// Attempts to load a USDZ accessory model for the given accessory type.
    /// Convention: file named "accessory_<rawValue>.usdz" (e.g., "accessory_hat.usdz").
    static func loadAccessoryModel(for accessory: AvatarAccessory) -> SCNNode? {
        guard accessory != .none else { return nil }
        return loadModel(named: "accessory_\(accessory.rawValue)")
    }

    // MARK: - Build Full Scene

    static func buildScene(config: AvatarConfig, size: CGFloat) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        let rootNode = buildCharacter(config: config, scale: size / 200.0)
        rootNode.name = NodeName.root
        scene.rootNode.addChildNode(rootNode)

        addLighting(to: scene)
        return scene
    }

    // MARK: - Character Assembly

    static func buildCharacter(config: AvatarConfig, scale: CGFloat = 1.0) -> SCNNode {
        // Try loading a skin variant GLB first (e.g. avatar_body_knight.glb)
        if let skinId = config.equippedSkinId,
           let skinBody = GLBModelLoader.loadSkinModel(skinId: skinId) {
            let root = SCNNode()
            root.name = NodeName.root
            skinBody.name = NodeName.body
            root.addChildNode(skinBody)
            root.scale = SCNVector3(scale, scale, scale)
            return root
        }

        // Try loading a custom body model (USDZ or GLB)
        if let customBody = loadModel(named: "avatar_body") {
            let root = SCNNode()
            root.name = NodeName.root
            customBody.name = NodeName.body
            root.addChildNode(customBody)

            // Create anchor nodes on the custom model for accessories
            let headAnchor = customBody.childNode(withName: NodeName.head, recursively: true) ?? customBody
            let hatAnchor = SCNNode()
            hatAnchor.name = NodeName.hatAnchor
            hatAnchor.position = SCNVector3(0, 0.35, 0)
            headAnchor.addChildNode(hatAnchor)

            let glassesAnchor = SCNNode()
            glassesAnchor.name = NodeName.glassesAnchor
            glassesAnchor.position = SCNVector3(0, 0.05, 0.35)
            headAnchor.addChildNode(glassesAnchor)

            // Try loading a custom accessory model, fall back to procedural
            if config.accessory != .none, let customAccessory = loadAccessoryModel(for: config.accessory) {
                customAccessory.name = NodeName.accessory
                let anchor = accessoryAnchorNode(for: config.accessory, on: headAnchor)
                anchor.addChildNode(customAccessory)
            } else {
                let bodyColor = uiColor(for: config.bodyColor)
                attachAccessory(to: root, headNode: headAnchor, accessory: config.accessory, bodyColor: bodyColor)
            }

            root.scale = SCNVector3(scale, scale, scale)
            return root
        }

        // Procedural fallback
        let root = SCNNode()
        root.name = NodeName.root

        let bodyColor = uiColor(for: config.bodyColor)
        let darkerBody = bodyColor.darkened(by: 0.15)

        // Body (capsule torso)
        let bodyGeo = SCNCapsule(capRadius: 0.35, height: 0.9)
        bodyGeo.firstMaterial?.diffuse.contents = bodyColor
        bodyGeo.firstMaterial?.lightingModel = .phong
        bodyGeo.firstMaterial?.specular.contents = UIColor.white.withAlphaComponent(0.3)
        let bodyNode = SCNNode(geometry: bodyGeo)
        bodyNode.name = NodeName.body
        bodyNode.position = SCNVector3(0, 0, 0)
        root.addChildNode(bodyNode)

        // Head (sphere, sitting on top of body)
        let headGeo = SCNSphere(radius: 0.4)
        headGeo.firstMaterial?.diffuse.contents = bodyColor
        headGeo.firstMaterial?.lightingModel = .phong
        headGeo.firstMaterial?.specular.contents = UIColor.white.withAlphaComponent(0.3)
        let headNode = SCNNode(geometry: headGeo)
        headNode.name = NodeName.head
        headNode.position = SCNVector3(0, 0.85, 0)
        root.addChildNode(headNode)

        // Eyes
        addEyes(to: headNode, style: config.eyeStyle)

        // Mouth
        addMouth(to: headNode, style: config.mouthStyle)

        // Arms
        let armGeo = SCNCapsule(capRadius: 0.1, height: 0.55)
        armGeo.firstMaterial?.diffuse.contents = darkerBody
        armGeo.firstMaterial?.lightingModel = .phong

        let leftArm = SCNNode(geometry: armGeo.copy() as? SCNCapsule ?? armGeo)
        leftArm.name = NodeName.leftArm
        leftArm.position = SCNVector3(-0.5, 0.05, 0)
        leftArm.eulerAngles = SCNVector3(0, 0, Float.pi * 0.12)
        root.addChildNode(leftArm)

        let rightArm = SCNNode(geometry: armGeo.copy() as? SCNCapsule ?? armGeo)
        rightArm.name = NodeName.rightArm
        rightArm.position = SCNVector3(0.5, 0.05, 0)
        rightArm.eulerAngles = SCNVector3(0, 0, -Float.pi * 0.12)
        root.addChildNode(rightArm)

        // Legs
        let legGeo = SCNCapsule(capRadius: 0.12, height: 0.5)
        legGeo.firstMaterial?.diffuse.contents = darkerBody
        legGeo.firstMaterial?.lightingModel = .phong

        let leftLeg = SCNNode(geometry: legGeo.copy() as? SCNCapsule ?? legGeo)
        leftLeg.name = NodeName.leftLeg
        leftLeg.position = SCNVector3(-0.18, -0.7, 0)
        root.addChildNode(leftLeg)

        let rightLeg = SCNNode(geometry: legGeo.copy() as? SCNCapsule ?? legGeo)
        rightLeg.name = NodeName.rightLeg
        rightLeg.position = SCNVector3(0.18, -0.7, 0)
        root.addChildNode(rightLeg)

        // Accessory anchors
        let hatAnchor = SCNNode()
        hatAnchor.name = NodeName.hatAnchor
        hatAnchor.position = SCNVector3(0, 0.35, 0)
        headNode.addChildNode(hatAnchor)

        let glassesAnchor = SCNNode()
        glassesAnchor.name = NodeName.glassesAnchor
        glassesAnchor.position = SCNVector3(0, 0.05, 0.35)
        headNode.addChildNode(glassesAnchor)

        // Attach accessory
        attachAccessory(to: root, headNode: headNode, accessory: config.accessory, bodyColor: bodyColor)

        // Scale entire character
        root.scale = SCNVector3(scale, scale, scale)

        return root
    }

    // MARK: - Eyes

    private static func addEyes(to headNode: SCNNode, style: AvatarEyeStyle) {
        let eyeSpacing: Float = 0.16
        let eyeForward: Float = 0.34
        let eyeHeight: Float = 0.08

        switch style {
        case .normal:
            let eyeGeo = SCNSphere(radius: 0.065)
            eyeGeo.firstMaterial?.diffuse.contents = UIColor.white
            let pupilGeo = SCNSphere(radius: 0.035)
            pupilGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1)

            for side: Float in [-1, 1] {
                let eye = SCNNode(geometry: eyeGeo.copy() as? SCNSphere ?? eyeGeo)
                eye.position = SCNVector3(side * eyeSpacing, eyeHeight, eyeForward)
                let pupil = SCNNode(geometry: pupilGeo.copy() as? SCNSphere ?? pupilGeo)
                pupil.position = SCNVector3(0, 0, 0.04)
                eye.addChildNode(pupil)
                headNode.addChildNode(eye)
            }

        case .happy:
            for side: Float in [-1, 1] {
                let arc = SCNTorus(ringRadius: 0.05, pipeRadius: 0.015)
                arc.firstMaterial?.diffuse.contents = UIColor.white
                let eye = SCNNode(geometry: arc)
                eye.position = SCNVector3(side * eyeSpacing, eyeHeight, eyeForward)
                eye.eulerAngles = SCNVector3(Float.pi * 0.5, 0, 0)
                eye.scale = SCNVector3(1, 1, 0.3)
                headNode.addChildNode(eye)
            }

        case .cool:
            let eyeGeo = SCNBox(width: 0.1, height: 0.04, length: 0.03, chamferRadius: 0.015)
            eyeGeo.firstMaterial?.diffuse.contents = UIColor.white
            for side: Float in [-1, 1] {
                let eye = SCNNode(geometry: eyeGeo.copy() as? SCNBox ?? eyeGeo)
                eye.position = SCNVector3(side * eyeSpacing, eyeHeight, eyeForward)
                headNode.addChildNode(eye)
            }

        case .surprised:
            let eyeGeo = SCNSphere(radius: 0.08)
            eyeGeo.firstMaterial?.diffuse.contents = UIColor.white
            let pupilGeo = SCNSphere(radius: 0.03)
            pupilGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1)
            for side: Float in [-1, 1] {
                let eye = SCNNode(geometry: eyeGeo.copy() as? SCNSphere ?? eyeGeo)
                eye.position = SCNVector3(side * eyeSpacing, eyeHeight, eyeForward)
                let pupil = SCNNode(geometry: pupilGeo.copy() as? SCNSphere ?? pupilGeo)
                pupil.position = SCNVector3(0, 0, 0.06)
                eye.addChildNode(pupil)
                headNode.addChildNode(eye)
            }

        case .sleepy:
            let eyeGeo = SCNCapsule(capRadius: 0.015, height: 0.09)
            eyeGeo.firstMaterial?.diffuse.contents = UIColor.white
            for side: Float in [-1, 1] {
                let eye = SCNNode(geometry: eyeGeo.copy() as? SCNCapsule ?? eyeGeo)
                eye.position = SCNVector3(side * eyeSpacing, eyeHeight, eyeForward)
                eye.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
                headNode.addChildNode(eye)
            }

        case .wink:
            // Left eye normal
            let eyeGeo = SCNSphere(radius: 0.065)
            eyeGeo.firstMaterial?.diffuse.contents = UIColor.white
            let pupilGeo = SCNSphere(radius: 0.035)
            pupilGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1)
            let leftEye = SCNNode(geometry: eyeGeo)
            leftEye.position = SCNVector3(-eyeSpacing, eyeHeight, eyeForward)
            let pupil = SCNNode(geometry: pupilGeo)
            pupil.position = SCNVector3(0, 0, 0.04)
            leftEye.addChildNode(pupil)
            headNode.addChildNode(leftEye)
            // Right eye winking (line)
            let winkGeo = SCNCapsule(capRadius: 0.015, height: 0.07)
            winkGeo.firstMaterial?.diffuse.contents = UIColor.white
            let rightEye = SCNNode(geometry: winkGeo)
            rightEye.position = SCNVector3(eyeSpacing, eyeHeight, eyeForward)
            rightEye.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            headNode.addChildNode(rightEye)

        case .stars:
            for side: Float in [-1, 1] {
                let star = makeStarNode(size: 0.07, color: .white)
                star.position = SCNVector3(side * eyeSpacing, eyeHeight, eyeForward)
                headNode.addChildNode(star)
            }

        case .hearts:
            for side: Float in [-1, 1] {
                let heart = makeHeartNode(size: 0.07, color: UIColor(red: 1, green: 0.4, blue: 0.5, alpha: 1))
                heart.position = SCNVector3(side * eyeSpacing, eyeHeight, eyeForward)
                headNode.addChildNode(heart)
            }
        }
    }

    // MARK: - Mouth

    private static func addMouth(to headNode: SCNNode, style: AvatarMouthStyle) {
        let mouthForward: Float = 0.35
        let mouthHeight: Float = -0.12

        switch style {
        case .smile:
            let geo = SCNCapsule(capRadius: 0.02, height: 0.12)
            geo.firstMaterial?.diffuse.contents = UIColor.white
            let node = SCNNode(geometry: geo)
            node.name = NodeName.mouth
            node.position = SCNVector3(0, mouthHeight, mouthForward)
            node.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            headNode.addChildNode(node)

        case .grin:
            let geo = SCNCapsule(capRadius: 0.025, height: 0.16)
            geo.firstMaterial?.diffuse.contents = UIColor.white
            let node = SCNNode(geometry: geo)
            node.name = NodeName.mouth
            node.position = SCNVector3(0, mouthHeight, mouthForward)
            node.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            headNode.addChildNode(node)

        case .neutral:
            let geo = SCNBox(width: 0.1, height: 0.02, length: 0.02, chamferRadius: 0.005)
            geo.firstMaterial?.diffuse.contents = UIColor.white
            let node = SCNNode(geometry: geo)
            node.name = NodeName.mouth
            node.position = SCNVector3(0, mouthHeight, mouthForward)
            headNode.addChildNode(node)

        case .open:
            let geo = SCNSphere(radius: 0.05)
            geo.firstMaterial?.diffuse.contents = UIColor(red: 0.2, green: 0.1, blue: 0.15, alpha: 1)
            let node = SCNNode(geometry: geo)
            node.name = NodeName.mouth
            node.position = SCNVector3(0, mouthHeight, mouthForward)
            node.scale = SCNVector3(1, 0.7, 0.5)
            headNode.addChildNode(node)

        case .tongue:
            let mouthGeo = SCNCapsule(capRadius: 0.02, height: 0.1)
            mouthGeo.firstMaterial?.diffuse.contents = UIColor.white
            let mouthNode = SCNNode(geometry: mouthGeo)
            mouthNode.name = NodeName.mouth
            mouthNode.position = SCNVector3(0, mouthHeight, mouthForward)
            mouthNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            headNode.addChildNode(mouthNode)

            let tongueGeo = SCNSphere(radius: 0.03)
            tongueGeo.firstMaterial?.diffuse.contents = UIColor(red: 1, green: 0.5, blue: 0.6, alpha: 1)
            let tongue = SCNNode(geometry: tongueGeo)
            tongue.position = SCNVector3(0, mouthHeight - 0.04, mouthForward + 0.01)
            tongue.scale = SCNVector3(1, 0.6, 0.8)
            headNode.addChildNode(tongue)

        case .cat:
            // Small "w" shape using two small arcs
            let leftArc = SCNTorus(ringRadius: 0.03, pipeRadius: 0.01)
            leftArc.firstMaterial?.diffuse.contents = UIColor.white
            let leftNode = SCNNode(geometry: leftArc)
            leftNode.position = SCNVector3(-0.03, mouthHeight, mouthForward)
            leftNode.eulerAngles = SCNVector3(Float.pi * 0.5, 0, 0)
            leftNode.scale = SCNVector3(1, 1, 0.4)
            headNode.addChildNode(leftNode)

            let rightArc = SCNTorus(ringRadius: 0.03, pipeRadius: 0.01)
            rightArc.firstMaterial?.diffuse.contents = UIColor.white
            let rightNode = SCNNode(geometry: rightArc)
            rightNode.position = SCNVector3(0.03, mouthHeight, mouthForward)
            rightNode.eulerAngles = SCNVector3(Float.pi * 0.5, 0, 0)
            rightNode.scale = SCNVector3(1, 1, 0.4)
            headNode.addChildNode(rightNode)

        case .smirk:
            let geo = SCNCapsule(capRadius: 0.018, height: 0.08)
            geo.firstMaterial?.diffuse.contents = UIColor.white
            let node = SCNNode(geometry: geo)
            node.name = NodeName.mouth
            node.position = SCNVector3(0.04, mouthHeight, mouthForward)
            node.eulerAngles = SCNVector3(0, 0, Float.pi / 2 + 0.3)
            headNode.addChildNode(node)
        }
    }

    // MARK: - Accessories

    static func attachAccessory(to root: SCNNode, headNode: SCNNode, accessory: AvatarAccessory, bodyColor: UIColor) {
        // Remove old accessory
        root.childNode(withName: NodeName.accessory, recursively: true)?.removeFromParentNode()
        headNode.childNode(withName: NodeName.accessory, recursively: true)?.removeFromParentNode()

        switch accessory {
        case .none:
            break

        case .hat:
            let brim = SCNCylinder(radius: 0.45, height: 0.04)
            brim.firstMaterial?.diffuse.contents = bodyColor.darkened(by: 0.3)
            let brimNode = SCNNode(geometry: brim)
            brimNode.position = SCNVector3(0, 0, 0)

            let top = SCNCylinder(radius: 0.3, height: 0.25)
            top.firstMaterial?.diffuse.contents = bodyColor.darkened(by: 0.25)
            let topNode = SCNNode(geometry: top)
            topNode.position = SCNVector3(0, 0.14, 0)

            let hatGroup = SCNNode()
            hatGroup.name = NodeName.accessory
            hatGroup.addChildNode(brimNode)
            hatGroup.addChildNode(topNode)
            hatGroup.position = SCNVector3(0, 0.38, 0)
            headNode.addChildNode(hatGroup)

        case .crown:
            let baseGeo = SCNCylinder(radius: 0.28, height: 0.06)
            baseGeo.firstMaterial?.diffuse.contents = UIColor(red: 1, green: 0.84, blue: 0, alpha: 1)
            baseGeo.firstMaterial?.specular.contents = UIColor.white
            let base = SCNNode(geometry: baseGeo)

            let crownGroup = SCNNode()
            crownGroup.name = NodeName.accessory

            crownGroup.addChildNode(base)

            // Crown points
            for i in 0..<5 {
                let angle = Float(i) * (Float.pi * 2 / 5)
                let pointGeo = SCNCone(topRadius: 0, bottomRadius: 0.05, height: 0.15)
                pointGeo.firstMaterial?.diffuse.contents = UIColor(red: 1, green: 0.84, blue: 0, alpha: 1)
                pointGeo.firstMaterial?.specular.contents = UIColor.white
                let point = SCNNode(geometry: pointGeo)
                point.position = SCNVector3(
                    sin(angle) * 0.2,
                    0.1,
                    cos(angle) * 0.2
                )
                crownGroup.addChildNode(point)

                // Gem on each point
                let gemGeo = SCNSphere(radius: 0.02)
                gemGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.9, green: 0.1, blue: 0.2, alpha: 1)
                gemGeo.firstMaterial?.specular.contents = UIColor.white
                let gem = SCNNode(geometry: gemGeo)
                gem.position = SCNVector3(
                    sin(angle) * 0.2,
                    0.18,
                    cos(angle) * 0.2
                )
                crownGroup.addChildNode(gem)
            }

            crownGroup.position = SCNVector3(0, 0.38, 0)
            headNode.addChildNode(crownGroup)

        case .glasses:
            let glassesGroup = makeGlasses(color: UIColor(white: 0.2, alpha: 0.85), lensColor: UIColor(white: 0.9, alpha: 0.3))
            glassesGroup.name = NodeName.accessory
            glassesGroup.position = SCNVector3(0, 0.05, 0.34)
            headNode.addChildNode(glassesGroup)

        case .sunglasses:
            let glassesGroup = makeGlasses(color: UIColor(white: 0.1, alpha: 0.95), lensColor: UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 0.85))
            glassesGroup.name = NodeName.accessory
            glassesGroup.position = SCNVector3(0, 0.05, 0.34)
            headNode.addChildNode(glassesGroup)

        case .headband:
            let bandGeo = SCNTorus(ringRadius: 0.38, pipeRadius: 0.03)
            bandGeo.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.85)
            let band = SCNNode(geometry: bandGeo)
            band.name = NodeName.accessory
            band.position = SCNVector3(0, 0.18, 0)
            band.eulerAngles = SCNVector3(Float.pi * 0.08, 0, 0)
            headNode.addChildNode(band)

        case .antenna:
            let stickGeo = SCNCylinder(radius: 0.015, height: 0.3)
            stickGeo.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.7)
            let stick = SCNNode(geometry: stickGeo)
            stick.position = SCNVector3(0, 0.15, 0)

            let ballGeo = SCNSphere(radius: 0.05)
            ballGeo.firstMaterial?.diffuse.contents = UIColor(red: 1, green: 0.9, blue: 0, alpha: 1)
            ballGeo.firstMaterial?.emission.contents = UIColor(red: 1, green: 0.9, blue: 0, alpha: 0.3)
            let ball = SCNNode(geometry: ballGeo)
            ball.position = SCNVector3(0, 0.32, 0)

            let antennaGroup = SCNNode()
            antennaGroup.name = NodeName.accessory
            antennaGroup.addChildNode(stick)
            antennaGroup.addChildNode(ball)
            antennaGroup.position = SCNVector3(0, 0.38, 0)
            headNode.addChildNode(antennaGroup)

        case .bow:
            let bowGroup = SCNNode()
            bowGroup.name = NodeName.accessory

            // Center knot
            let knotGeo = SCNSphere(radius: 0.04)
            knotGeo.firstMaterial?.diffuse.contents = UIColor(red: 1, green: 0.4, blue: 0.6, alpha: 1)
            let knot = SCNNode(geometry: knotGeo)
            bowGroup.addChildNode(knot)

            // Loops
            for side: Float in [-1, 1] {
                let loopGeo = SCNSphere(radius: 0.07)
                loopGeo.firstMaterial?.diffuse.contents = UIColor(red: 1, green: 0.4, blue: 0.6, alpha: 1)
                let loop = SCNNode(geometry: loopGeo)
                loop.position = SCNVector3(side * 0.08, 0.02, 0)
                loop.scale = SCNVector3(1, 0.6, 0.5)
                bowGroup.addChildNode(loop)
            }

            bowGroup.position = SCNVector3(0.25, 0.2, 0.2)
            headNode.addChildNode(bowGroup)
        }
    }

    /// Returns the appropriate anchor node for a given accessory type on a head node.
    private static func accessoryAnchorNode(for accessory: AvatarAccessory, on headNode: SCNNode) -> SCNNode {
        switch accessory {
        case .glasses, .sunglasses:
            return headNode.childNode(withName: NodeName.glassesAnchor, recursively: true) ?? headNode
        case .hat, .crown, .headband, .antenna, .bow:
            return headNode.childNode(withName: NodeName.hatAnchor, recursively: true) ?? headNode
        case .none:
            return headNode
        }
    }

    // MARK: - Glasses Helper

    private static func makeGlasses(color: UIColor, lensColor: UIColor) -> SCNNode {
        let group = SCNNode()

        let lensRadius: CGFloat = 0.09
        let lensThickness: CGFloat = 0.02
        let spacing: Float = 0.16

        // Lens frames
        for side: Float in [-1, 1] {
            let frameGeo = SCNTorus(ringRadius: lensRadius, pipeRadius: 0.012)
            frameGeo.firstMaterial?.diffuse.contents = color
            let frame = SCNNode(geometry: frameGeo)
            frame.position = SCNVector3(side * spacing, 0, 0)
            frame.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
            group.addChildNode(frame)

            // Lens fill
            let lensGeo = SCNCylinder(radius: lensRadius - 0.01, height: lensThickness)
            lensGeo.firstMaterial?.diffuse.contents = lensColor
            lensGeo.firstMaterial?.transparency = 0.5
            let lens = SCNNode(geometry: lensGeo)
            lens.position = SCNVector3(side * spacing, 0, 0)
            lens.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
            group.addChildNode(lens)
        }

        // Bridge
        let bridgeGeo = SCNCapsule(capRadius: 0.01, height: CGFloat(spacing * 2 - Float(lensRadius) * 2))
        bridgeGeo.firstMaterial?.diffuse.contents = color
        let bridge = SCNNode(geometry: bridgeGeo)
        bridge.position = SCNVector3(0, 0, 0)
        bridge.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        group.addChildNode(bridge)

        // Temples (arms going back to ears)
        for side: Float in [-1, 1] {
            let templeGeo = SCNCapsule(capRadius: 0.008, height: 0.25)
            templeGeo.firstMaterial?.diffuse.contents = color
            let temple = SCNNode(geometry: templeGeo)
            temple.position = SCNVector3(side * (spacing + Float(lensRadius)), 0, -0.12)
            temple.eulerAngles = SCNVector3(Float.pi / 2 - 0.2, 0, 0)
            group.addChildNode(temple)
        }

        return group
    }

    // MARK: - Shape Helpers

    private static func makeStarNode(size: Float, color: UIColor) -> SCNNode {
        // Approximate star with overlapping boxes rotated
        let group = SCNNode()
        for i in 0..<3 {
            let box = SCNBox(width: CGFloat(size), height: CGFloat(size * 0.35), length: 0.02, chamferRadius: 0.005)
            box.firstMaterial?.diffuse.contents = color
            let node = SCNNode(geometry: box)
            node.eulerAngles = SCNVector3(0, 0, Float(i) * Float.pi / 3)
            group.addChildNode(node)
        }
        return group
    }

    private static func makeHeartNode(size: Float, color: UIColor) -> SCNNode {
        let group = SCNNode()

        // Two overlapping spheres + a rotated box for the bottom
        let r = CGFloat(size * 0.4)
        let sphereGeo = SCNSphere(radius: r)
        sphereGeo.firstMaterial?.diffuse.contents = color

        let left = SCNNode(geometry: sphereGeo)
        left.position = SCNVector3(-size * 0.22, size * 0.12, 0)
        group.addChildNode(left)

        let right = SCNNode(geometry: sphereGeo.copy() as? SCNSphere ?? sphereGeo)
        right.position = SCNVector3(size * 0.22, size * 0.12, 0)
        group.addChildNode(right)

        let bottomGeo = SCNBox(width: CGFloat(size * 0.62), height: CGFloat(size * 0.62), length: CGFloat(size * 0.5), chamferRadius: 0.005)
        bottomGeo.firstMaterial?.diffuse.contents = color
        let bottom = SCNNode(geometry: bottomGeo)
        bottom.position = SCNVector3(0, -size * 0.05, 0)
        bottom.eulerAngles = SCNVector3(0, 0, Float.pi / 4)
        bottom.scale = SCNVector3(1, 0.8, 0.5)
        group.addChildNode(bottom)

        return group
    }

    // MARK: - Lighting

    /// Public entry point for external scenes (e.g., map annotation).
    static func addLightingPublic(to scene: SCNScene) {
        addLighting(to: scene)
    }

    private static func addLighting(to scene: SCNScene) {
        // Key light
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.intensity = 800
        keyLight.color = UIColor.white
        keyLight.castsShadow = false
        let keyNode = SCNNode()
        keyNode.light = keyLight
        keyNode.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 6, 0)
        scene.rootNode.addChildNode(keyNode)

        // Fill light
        let fillLight = SCNLight()
        fillLight.type = .directional
        fillLight.intensity = 400
        fillLight.color = UIColor(white: 0.9, alpha: 1)
        let fillNode = SCNNode()
        fillNode.light = fillLight
        fillNode.eulerAngles = SCNVector3(-Float.pi / 6, -Float.pi / 4, 0)
        scene.rootNode.addChildNode(fillNode)

        // Ambient
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 300
        ambient.color = UIColor(white: 0.85, alpha: 1)
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)
    }

    // MARK: - Color Mapping

    static func uiColor(for bodyColor: AvatarBodyColor) -> UIColor {
        switch bodyColor {
        case .red: return UIColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 1)
        case .orange: return UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1)
        case .yellow: return UIColor(red: 1.0, green: 0.88, blue: 0.3, alpha: 1)
        case .green: return UIColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1)
        case .blue: return UIColor(red: 0.3, green: 0.55, blue: 0.95, alpha: 1)
        case .indigo: return UIColor(red: 0.35, green: 0.3, blue: 0.8, alpha: 1)
        case .purple: return UIColor(red: 0.65, green: 0.35, blue: 0.9, alpha: 1)
        case .pink: return UIColor(red: 1.0, green: 0.45, blue: 0.65, alpha: 1)
        case .teal: return UIColor(red: 0.2, green: 0.75, blue: 0.75, alpha: 1)
        case .mint: return UIColor(red: 0.4, green: 0.9, blue: 0.8, alpha: 1)
        case .cyan: return UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1)
        case .brown: return UIColor(red: 0.6, green: 0.45, blue: 0.3, alpha: 1)
        }
    }
}

// MARK: - UIColor Extension

extension UIColor {
    func darkened(by percentage: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(
            red: max(r - percentage, 0),
            green: max(g - percentage, 0),
            blue: max(b - percentage, 0),
            alpha: a
        )
    }
}
