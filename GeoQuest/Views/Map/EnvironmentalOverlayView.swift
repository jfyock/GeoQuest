import SceneKit
import SwiftUI

// MARK: - Map Annotation View for 3D Atmospheric Elements

/// Renders a single atmospheric element as a 3D SceneKit annotation view.
/// Each element is geo-anchored so it pans and rotates with the map,
/// and uses the same camera-orbit perspective as the player avatar.
struct AtmosphericAnnotationView: View {
    let element: AtmosphericElement
    var cameraPitch: Double = 0
    var zoomScale: CGFloat = 1.0

    var body: some View {
        MapElement3DView(
            type: elementType,
            cameraPitch: cameraPitch
        )
        .frame(width: frameSize.width, height: frameSize.height)
        .scaleEffect(zoomScale)
        .allowsHitTesting(false)
    }

    private var elementType: MapElement3DView.ElementType {
        switch element.kind {
        case .bird: return .bird(heading: element.heading)
        case .boat: return .boat(heading: element.heading)
        case .cloud: return .cloud
        case .plane: return .plane(heading: element.heading)
        case .hotAirBalloon: return .hotAirBalloon
        case .butterfly: return .butterfly
        }
    }

    private var frameSize: CGSize {
        switch element.kind {
        case .bird: return CGSize(width: 50, height: 40)
        case .boat: return CGSize(width: 55, height: 50)
        case .cloud: return CGSize(width: 70, height: 45)
        case .plane: return CGSize(width: 48, height: 52)
        case .hotAirBalloon: return CGSize(width: 42, height: 56)
        case .butterfly: return CGSize(width: 28, height: 24)
        }
    }
}

// MARK: - Generic 3D Map Element (SceneKit)

/// A lightweight SceneKit view that renders a 3D element with camera orbit
/// matching the map's camera pitch. Shared by all environmental elements
/// and quest markers.
struct MapElement3DView: UIViewRepresentable {
    enum ElementType: Equatable {
        case bird(heading: Double)
        case boat(heading: Double)
        case cloud
        case plane(heading: Double)
        case hotAirBalloon
        case butterfly
        case questMarker(red: CGFloat, green: CGFloat, blue: CGFloat, isCompleted: Bool)
    }

    let type: ElementType
    var cameraPitch: Double = 0

    private static let cameraNodeName = "elemCam"

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.preferredFramesPerSecond = 15
        scnView.contentScaleFactor = UIScreen.main.scale
        scnView.antialiasingMode = .none
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = false

        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        let rootNode = ElementSceneBuilder.build(type: type)
        rootNode.name = "elementRoot"
        scene.rootNode.addChildNode(rootNode)

        // Camera with orthographic projection
        let cameraNode = SCNNode()
        cameraNode.name = Self.cameraNodeName
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = orthoScale
        cameraNode.camera = camera
        scene.rootNode.addChildNode(cameraNode)
        Self.updateCameraForPitch(cameraNode: cameraNode, pitch: cameraPitch)

        // Simple lighting
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .directional
        keyLight.light?.intensity = 800
        keyLight.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 6, 0)
        scene.rootNode.addChildNode(keyLight)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 400
        scene.rootNode.addChildNode(ambient)

        scnView.scene = scene

        // Start element-specific animations
        ElementSceneBuilder.animate(rootNode: rootNode, type: type)

        context.coordinator.currentPitch = cameraPitch
        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        guard let scene = scnView.scene,
              let cameraNode = scene.rootNode.childNode(
                  withName: Self.cameraNodeName, recursively: false
              ) else { return }

        // Update camera orbit immediately — no animation for real-time sync
        if context.coordinator.currentPitch != cameraPitch {
            context.coordinator.currentPitch = cameraPitch
            Self.updateCameraForPitch(cameraNode: cameraNode, pitch: cameraPitch)
        }
    }

    final class Coordinator {
        var currentPitch: Double = 0
    }

    // MARK: - Camera Orbit (same logic as Avatar3DMapView)

    private static func updateCameraForPitch(cameraNode: SCNNode, pitch: Double) {
        let clampedPitch = min(max(pitch, 0), 70)
        let t = clampedPitch / 70.0
        let orbitRadius: Float = 3.0
        let elevationDeg = 80.0 - t * 70.0
        let elevationRad = Float(elevationDeg * .pi / 180)
        let camY = Float(0.3) + orbitRadius * sin(elevationRad)
        let camZ = orbitRadius * cos(elevationRad)
        cameraNode.position = SCNVector3(0, camY, camZ)
        cameraNode.look(at: SCNVector3(0, 0.2, 0))
    }

    private var orthoScale: Double {
        switch type {
        case .cloud: return 1.4
        case .hotAirBalloon: return 1.0
        case .boat: return 1.1
        case .questMarker: return 1.0
        default: return 0.9
        }
    }
}

// MARK: - Element Scene Builder

/// Builds procedural 3D SceneKit geometry for each atmospheric element type.
enum ElementSceneBuilder {

    static func build(type: MapElement3DView.ElementType) -> SCNNode {
        switch type {
        case .bird(let heading): return buildBird(heading: heading)
        case .boat(let heading): return buildBoat(heading: heading)
        case .cloud: return buildCloud()
        case .plane(let heading): return buildPlane(heading: heading)
        case .hotAirBalloon: return buildBalloon()
        case .butterfly: return buildButterfly()
        case .questMarker(let r, let g, let b, let isCompleted):
            return buildQuestMarker(red: r, green: g, blue: b, isCompleted: isCompleted)
        }
    }

    static func animate(rootNode: SCNNode, type: MapElement3DView.ElementType) {
        switch type {
        case .bird: animateBird(rootNode)
        case .boat: animateBoat(rootNode)
        case .cloud: animateCloud(rootNode)
        case .plane: animatePlane(rootNode)
        case .hotAirBalloon: animateBalloon(rootNode)
        case .butterfly: animateButterfly(rootNode)
        case .questMarker: animateQuestMarker(rootNode)
        }
    }

    // MARK: - Bird (3D body + flapping wings in V-formation)

    private static func buildBird(heading: Double) -> SCNNode {
        let root = SCNNode()
        root.eulerAngles.y = Float(heading * .pi / 180)

        for i in 0..<3 {
            let bird = SCNNode()
            let offsetX = Float(i - 1) * 0.25
            let offsetZ = abs(Float(i - 1)) * 0.1
            bird.position = SCNVector3(offsetX, 0, offsetZ)

            // Body
            let bodyGeo = SCNSphere(radius: 0.06)
            bodyGeo.firstMaterial?.diffuse.contents = UIColor(white: 0.15, alpha: 1)
            bodyGeo.firstMaterial?.lightingModel = .phong
            let body = SCNNode(geometry: bodyGeo)
            body.scale = SCNVector3(0.8, 0.6, 1.4)
            bird.addChildNode(body)

            // Wings
            let wingGeo = SCNBox(width: 0.22, height: 0.015, length: 0.1, chamferRadius: 0.005)
            wingGeo.firstMaterial?.diffuse.contents = UIColor(white: 0.2, alpha: 1)
            wingGeo.firstMaterial?.lightingModel = .phong

            let leftWing = SCNNode(geometry: wingGeo)
            leftWing.name = "leftWing_\(i)"
            leftWing.position = SCNVector3(-0.08, 0.015, 0)
            leftWing.pivot = SCNMatrix4MakeTranslation(0.08, 0, 0)
            bird.addChildNode(leftWing)

            let rightWingGeo = wingGeo.copy() as! SCNBox
            let rightWing = SCNNode(geometry: rightWingGeo)
            rightWing.name = "rightWing_\(i)"
            rightWing.position = SCNVector3(0.08, 0.015, 0)
            rightWing.pivot = SCNMatrix4MakeTranslation(-0.08, 0, 0)
            bird.addChildNode(rightWing)

            // Tail
            let tailGeo = SCNBox(width: 0.04, height: 0.01, length: 0.08, chamferRadius: 0.003)
            tailGeo.firstMaterial?.diffuse.contents = UIColor(white: 0.18, alpha: 1)
            let tail = SCNNode(geometry: tailGeo)
            tail.position = SCNVector3(0, 0, -0.1)
            bird.addChildNode(tail)

            root.addChildNode(bird)
        }

        return root
    }

    private static func animateBird(_ root: SCNNode) {
        for i in 0..<3 {
            let phase = Double(i) * 0.15
            if let left = root.childNode(withName: "leftWing_\(i)", recursively: true) {
                let flap = SCNAction.repeatForever(SCNAction.sequence([
                    SCNAction.wait(duration: phase),
                    SCNAction.rotateBy(x: 0, y: 0, z: CGFloat.pi * 0.35, duration: 0.2),
                    SCNAction.rotateBy(x: 0, y: 0, z: -CGFloat.pi * 0.35, duration: 0.25),
                ]))
                left.runAction(flap)
            }
            if let right = root.childNode(withName: "rightWing_\(i)", recursively: true) {
                let flap = SCNAction.repeatForever(SCNAction.sequence([
                    SCNAction.wait(duration: phase),
                    SCNAction.rotateBy(x: 0, y: 0, z: -CGFloat.pi * 0.35, duration: 0.2),
                    SCNAction.rotateBy(x: 0, y: 0, z: CGFloat.pi * 0.35, duration: 0.25),
                ]))
                right.runAction(flap)
            }
        }
    }

    // MARK: - Boat (3D hull + mast + sail + bobbing)

    private static func buildBoat(heading: Double) -> SCNNode {
        let root = SCNNode()
        root.eulerAngles.y = Float(heading * .pi / 180)

        // Hull
        let hullGeo = SCNBox(width: 0.5, height: 0.1, length: 0.18, chamferRadius: 0.05)
        hullGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.55, green: 0.35, blue: 0.2, alpha: 1)
        hullGeo.firstMaterial?.lightingModel = .phong
        hullGeo.firstMaterial?.specular.contents = UIColor.white.withAlphaComponent(0.2)
        let hull = SCNNode(geometry: hullGeo)
        hull.name = "hull"
        root.addChildNode(hull)

        // Mast
        let mastGeo = SCNCylinder(radius: 0.012, height: 0.4)
        mastGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.45, green: 0.3, blue: 0.15, alpha: 1)
        let mast = SCNNode(geometry: mastGeo)
        mast.position = SCNVector3(0, 0.25, 0)
        root.addChildNode(mast)

        // Sail
        let sailGeo = SCNBox(width: 0.18, height: 0.28, length: 0.01, chamferRadius: 0.005)
        sailGeo.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.92)
        sailGeo.firstMaterial?.lightingModel = .phong
        sailGeo.firstMaterial?.isDoubleSided = true
        let sail = SCNNode(geometry: sailGeo)
        sail.name = "sail"
        sail.position = SCNVector3(0.06, 0.25, 0.02)
        root.addChildNode(sail)

        // Wake
        let wakeGeo = SCNCylinder(radius: 0.12, height: 0.005)
        wakeGeo.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.3)
        let wake = SCNNode(geometry: wakeGeo)
        wake.position = SCNVector3(-0.2, -0.04, 0)
        wake.scale = SCNVector3(1.5, 1, 0.6)
        root.addChildNode(wake)

        return root
    }

    private static func animateBoat(_ root: SCNNode) {
        let bob = SCNAction.repeatForever(SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.04, z: 0, duration: 1.5),
            SCNAction.moveBy(x: 0, y: -0.04, z: 0, duration: 1.5),
        ]))
        bob.timingMode = .easeInEaseOut
        root.runAction(bob)

        if let hull = root.childNode(withName: "hull", recursively: false) {
            let roll = SCNAction.repeatForever(SCNAction.sequence([
                SCNAction.rotateBy(x: 0, y: 0, z: 0.06, duration: 2.0),
                SCNAction.rotateBy(x: 0, y: 0, z: -0.06, duration: 2.0),
            ]))
            roll.timingMode = .easeInEaseOut
            hull.runAction(roll)
        }
    }

    // MARK: - Cloud (cluster of overlapping spheres)

    private static func buildCloud() -> SCNNode {
        let root = SCNNode()
        let cloudColor = UIColor.white.withAlphaComponent(0.7)
        let positions: [(x: Float, y: Float, z: Float, r: CGFloat)] = [
            (0, 0, 0, 0.2),
            (-0.18, 0.03, 0.02, 0.16),
            (0.2, 0.02, -0.01, 0.17),
            (0.08, 0.08, 0.03, 0.14),
            (-0.08, -0.02, -0.02, 0.13),
        ]

        for pos in positions {
            let sphereGeo = SCNSphere(radius: pos.r)
            sphereGeo.firstMaterial?.diffuse.contents = cloudColor
            sphereGeo.firstMaterial?.lightingModel = .phong
            sphereGeo.firstMaterial?.specular.contents = UIColor.white.withAlphaComponent(0.15)
            let node = SCNNode(geometry: sphereGeo)
            node.position = SCNVector3(pos.x, pos.y, pos.z)
            root.addChildNode(node)
        }

        return root
    }

    private static func animateCloud(_ root: SCNNode) {
        let drift = SCNAction.repeatForever(SCNAction.sequence([
            SCNAction.moveBy(x: 0.03, y: 0.01, z: 0, duration: 4.0),
            SCNAction.moveBy(x: -0.03, y: -0.01, z: 0, duration: 4.0),
        ]))
        drift.timingMode = .easeInEaseOut
        root.runAction(drift)
    }

    // MARK: - Plane (fuselage + wings + tail, gains altitude)

    private static func buildPlane(heading: Double) -> SCNNode {
        let root = SCNNode()
        root.eulerAngles.y = Float(heading * .pi / 180)

        let bodyColor = UIColor.white.withAlphaComponent(0.95)
        let metalColor = UIColor(white: 0.7, alpha: 1)

        // Fuselage
        let fuselageGeo = SCNCapsule(capRadius: 0.04, height: 0.45)
        fuselageGeo.firstMaterial?.diffuse.contents = bodyColor
        fuselageGeo.firstMaterial?.lightingModel = .phong
        fuselageGeo.firstMaterial?.specular.contents = UIColor.white.withAlphaComponent(0.4)
        let fuselage = SCNNode(geometry: fuselageGeo)
        fuselage.eulerAngles.x = Float.pi / 2
        root.addChildNode(fuselage)

        // Wings
        let wingGeo = SCNBox(width: 0.6, height: 0.01, length: 0.12, chamferRadius: 0.005)
        wingGeo.firstMaterial?.diffuse.contents = bodyColor
        wingGeo.firstMaterial?.lightingModel = .phong
        let wings = SCNNode(geometry: wingGeo)
        wings.position = SCNVector3(0, 0.01, 0.04)
        root.addChildNode(wings)

        // Tail horizontal stabilizer
        let tailGeo = SCNBox(width: 0.2, height: 0.008, length: 0.06, chamferRadius: 0.003)
        tailGeo.firstMaterial?.diffuse.contents = bodyColor
        let tail = SCNNode(geometry: tailGeo)
        tail.position = SCNVector3(0, 0.01, -0.2)
        root.addChildNode(tail)

        // Vertical fin
        let finGeo = SCNBox(width: 0.008, height: 0.1, length: 0.08, chamferRadius: 0.003)
        finGeo.firstMaterial?.diffuse.contents = bodyColor
        let fin = SCNNode(geometry: finGeo)
        fin.position = SCNVector3(0, 0.06, -0.2)
        root.addChildNode(fin)

        // Engine pods
        for side: Float in [-1, 1] {
            let engineGeo = SCNCylinder(radius: 0.025, height: 0.06)
            engineGeo.firstMaterial?.diffuse.contents = metalColor
            let engine = SCNNode(geometry: engineGeo)
            engine.position = SCNVector3(side * 0.15, -0.01, 0.05)
            engine.eulerAngles.x = Float.pi / 2
            root.addChildNode(engine)
        }

        // Nose up — taking off
        root.eulerAngles.x = -0.12

        return root
    }

    private static func animatePlane(_ root: SCNNode) {
        // Climb
        let climb = SCNAction.repeatForever(SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.08, z: 0, duration: 6.0),
            SCNAction.moveBy(x: 0, y: -0.08, z: 0, duration: 6.0),
        ]))
        climb.timingMode = .easeInEaseOut
        root.runAction(climb)

        // Subtle bank
        let bank = SCNAction.repeatForever(SCNAction.sequence([
            SCNAction.rotateBy(x: 0, y: 0, z: 0.03, duration: 4.0),
            SCNAction.rotateBy(x: 0, y: 0, z: -0.03, duration: 4.0),
        ]))
        bank.timingMode = .easeInEaseOut
        root.runAction(bank)
    }

    // MARK: - Hot Air Balloon (envelope + basket + ropes)

    private static func buildBalloon() -> SCNNode {
        let root = SCNNode()

        let balloonColors: [UIColor] = [
            UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1),
            UIColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 1),
            UIColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1),
            UIColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1),
            UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1),
        ]
        let mainColor = balloonColors.randomElement()!

        // Envelope
        let envelopeGeo = SCNSphere(radius: 0.25)
        envelopeGeo.firstMaterial?.diffuse.contents = mainColor
        envelopeGeo.firstMaterial?.lightingModel = .phong
        envelopeGeo.firstMaterial?.specular.contents = UIColor.white.withAlphaComponent(0.3)
        let envelope = SCNNode(geometry: envelopeGeo)
        envelope.position = SCNVector3(0, 0.35, 0)
        envelope.scale = SCNVector3(1, 1.15, 1)
        root.addChildNode(envelope)

        // Stripes
        for i in 0..<3 {
            let stripeGeo = SCNCylinder(radius: 0.252, height: 0.02)
            stripeGeo.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.4)
            let stripe = SCNNode(geometry: stripeGeo)
            stripe.position = SCNVector3(0, 0.35 + Float(i - 1) * 0.1, 0)
            root.addChildNode(stripe)
        }

        // Ropes
        for side: Float in [-1, 1] {
            let ropeGeo = SCNCylinder(radius: 0.005, height: 0.18)
            ropeGeo.firstMaterial?.diffuse.contents = UIColor.brown.withAlphaComponent(0.6)
            let rope = SCNNode(geometry: ropeGeo)
            rope.position = SCNVector3(side * 0.06, 0.08, 0)
            root.addChildNode(rope)
        }

        // Basket
        let basketGeo = SCNBox(width: 0.1, height: 0.06, length: 0.1, chamferRadius: 0.01)
        basketGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.55, green: 0.35, blue: 0.15, alpha: 1)
        basketGeo.firstMaterial?.lightingModel = .phong
        let basket = SCNNode(geometry: basketGeo)
        basket.position = SCNVector3(0, -0.02, 0)
        root.addChildNode(basket)

        return root
    }

    private static func animateBalloon(_ root: SCNNode) {
        let float = SCNAction.repeatForever(SCNAction.sequence([
            SCNAction.moveBy(x: 0.02, y: 0.04, z: 0.01, duration: 3.0),
            SCNAction.moveBy(x: -0.02, y: -0.04, z: -0.01, duration: 3.0),
        ]))
        float.timingMode = .easeInEaseOut
        root.runAction(float)

        let rotate = SCNAction.repeatForever(SCNAction.sequence([
            SCNAction.rotateBy(x: 0, y: 0.1, z: 0, duration: 5.0),
            SCNAction.rotateBy(x: 0, y: -0.1, z: 0, duration: 5.0),
        ]))
        rotate.timingMode = .easeInEaseOut
        root.runAction(rotate)
    }

    // MARK: - Butterfly (tiny body + fluttering wings)

    private static func buildButterfly() -> SCNNode {
        let root = SCNNode()

        let wingColors: [UIColor] = [
            UIColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 0.85),
            UIColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 0.85),
            UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 0.85),
            UIColor(red: 0.9, green: 0.3, blue: 0.5, alpha: 0.85),
        ]
        let wingColor = wingColors.randomElement()!

        // Body
        let bodyGeo = SCNCylinder(radius: 0.008, height: 0.08)
        bodyGeo.firstMaterial?.diffuse.contents = UIColor(white: 0.15, alpha: 1)
        let body = SCNNode(geometry: bodyGeo)
        body.eulerAngles.x = Float.pi / 2
        root.addChildNode(body)

        // Upper wings
        for side: Float in [-1, 1] {
            let wingGeo = SCNBox(width: 0.06, height: 0.05, length: 0.005, chamferRadius: 0.015)
            wingGeo.firstMaterial?.diffuse.contents = wingColor
            wingGeo.firstMaterial?.lightingModel = .phong
            wingGeo.firstMaterial?.isDoubleSided = true
            let wing = SCNNode(geometry: wingGeo)
            wing.name = side < 0 ? "leftUpperWing" : "rightUpperWing"
            wing.position = SCNVector3(side * 0.035, 0.01, 0.01)
            wing.pivot = SCNMatrix4MakeTranslation(-side * 0.025, 0, 0)
            root.addChildNode(wing)
        }

        // Lower wings
        for side: Float in [-1, 1] {
            let wingGeo = SCNBox(width: 0.045, height: 0.04, length: 0.005, chamferRadius: 0.01)
            wingGeo.firstMaterial?.diffuse.contents = wingColor.withAlphaComponent(0.7)
            wingGeo.firstMaterial?.lightingModel = .phong
            wingGeo.firstMaterial?.isDoubleSided = true
            let wing = SCNNode(geometry: wingGeo)
            wing.name = side < 0 ? "leftLowerWing" : "rightLowerWing"
            wing.position = SCNVector3(side * 0.03, -0.005, -0.01)
            wing.pivot = SCNMatrix4MakeTranslation(-side * 0.02, 0, 0)
            root.addChildNode(wing)
        }

        // Antennae
        for side: Float in [-1, 1] {
            let antGeo = SCNCylinder(radius: 0.002, height: 0.04)
            antGeo.firstMaterial?.diffuse.contents = UIColor(white: 0.2, alpha: 1)
            let ant = SCNNode(geometry: antGeo)
            ant.position = SCNVector3(side * 0.01, 0.02, 0.04)
            ant.eulerAngles = SCNVector3(Float.pi * 0.3, 0, side * Float.pi * 0.2)
            root.addChildNode(ant)
        }

        return root
    }

    private static func animateButterfly(_ root: SCNNode) {
        for name in ["leftUpperWing", "leftLowerWing"] {
            if let wing = root.childNode(withName: name, recursively: false) {
                let flutter = SCNAction.repeatForever(SCNAction.sequence([
                    SCNAction.rotateBy(x: 0, y: CGFloat.pi * 0.4, z: 0, duration: 0.12),
                    SCNAction.rotateBy(x: 0, y: -CGFloat.pi * 0.4, z: 0, duration: 0.15),
                ]))
                wing.runAction(flutter)
            }
        }
        for name in ["rightUpperWing", "rightLowerWing"] {
            if let wing = root.childNode(withName: name, recursively: false) {
                let flutter = SCNAction.repeatForever(SCNAction.sequence([
                    SCNAction.rotateBy(x: 0, y: -CGFloat.pi * 0.4, z: 0, duration: 0.12),
                    SCNAction.rotateBy(x: 0, y: CGFloat.pi * 0.4, z: 0, duration: 0.15),
                ]))
                wing.runAction(flutter)
            }
        }

        let wander = SCNAction.repeatForever(SCNAction.sequence([
            SCNAction.moveBy(x: 0.03, y: 0.02, z: 0.01, duration: 0.8),
            SCNAction.moveBy(x: -0.02, y: -0.01, z: 0.02, duration: 0.6),
            SCNAction.moveBy(x: -0.01, y: 0.02, z: -0.03, duration: 0.7),
        ]))
        wander.timingMode = .easeInEaseOut
        root.runAction(wander)
    }

    // MARK: - Quest Marker (3D orb + pin + glow)

    static func buildQuestMarker(red: CGFloat, green: CGFloat, blue: CGFloat, isCompleted: Bool) -> SCNNode {
        let root = SCNNode()
        let questColor = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        let alpha: CGFloat = isCompleted ? 0.5 : 1.0

        // Main orb
        let orbGeo = SCNSphere(radius: 0.2)
        orbGeo.firstMaterial?.diffuse.contents = questColor.withAlphaComponent(alpha)
        orbGeo.firstMaterial?.lightingModel = .phong
        orbGeo.firstMaterial?.specular.contents = UIColor.white.withAlphaComponent(0.5)
        orbGeo.firstMaterial?.emission.contents = questColor.withAlphaComponent(0.15)
        let orb = SCNNode(geometry: orbGeo)
        orb.name = "questOrb"
        orb.position = SCNVector3(0, 0.35, 0)
        root.addChildNode(orb)

        // Outer glow ring
        let ringGeo = SCNTorus(ringRadius: 0.22, pipeRadius: 0.015)
        ringGeo.firstMaterial?.diffuse.contents = questColor.withAlphaComponent(0.3 * alpha)
        ringGeo.firstMaterial?.emission.contents = questColor.withAlphaComponent(0.2 * alpha)
        let ring = SCNNode(geometry: ringGeo)
        ring.name = "questRing"
        ring.position = SCNVector3(0, 0.35, 0)
        root.addChildNode(ring)

        // Pin cone pointing down
        let coneGeo = SCNCone(topRadius: 0.08, bottomRadius: 0.005, height: 0.2)
        coneGeo.firstMaterial?.diffuse.contents = questColor.withAlphaComponent(alpha)
        coneGeo.firstMaterial?.lightingModel = .phong
        let cone = SCNNode(geometry: coneGeo)
        cone.position = SCNVector3(0, 0.05, 0)
        root.addChildNode(cone)

        // Completed checkmark indicator
        if isCompleted {
            let checkGeo = SCNSphere(radius: 0.08)
            checkGeo.firstMaterial?.diffuse.contents = UIColor(red: 0.24, green: 0.85, blue: 0.48, alpha: 1)
            checkGeo.firstMaterial?.emission.contents = UIColor(red: 0.24, green: 0.85, blue: 0.48, alpha: 0.3)
            let check = SCNNode(geometry: checkGeo)
            check.position = SCNVector3(0.18, 0.5, 0)
            root.addChildNode(check)
        }

        return root
    }

    private static func animateQuestMarker(_ root: SCNNode) {
        if let orb = root.childNode(withName: "questOrb", recursively: false) {
            let bob = SCNAction.repeatForever(SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.04, z: 0, duration: 1.2),
                SCNAction.moveBy(x: 0, y: -0.04, z: 0, duration: 1.2),
            ]))
            bob.timingMode = .easeInEaseOut
            orb.runAction(bob)
        }

        if let ring = root.childNode(withName: "questRing", recursively: false) {
            let spin = SCNAction.repeatForever(
                SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 6.0)
            )
            ring.runAction(spin)

            let bob = SCNAction.repeatForever(SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.04, z: 0, duration: 1.2),
                SCNAction.moveBy(x: 0, y: -0.04, z: 0, duration: 1.2),
            ]))
            bob.timingMode = .easeInEaseOut
            ring.runAction(bob)
        }
    }
}
