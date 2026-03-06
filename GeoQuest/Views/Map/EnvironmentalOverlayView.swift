import SwiftUI

// MARK: - Map Annotation View for Atmospheric Elements

/// Renders a single atmospheric element as a map annotation view.
/// Each element is geo-anchored so it pans and rotates with the map.
struct AtmosphericAnnotationView: View {
    let element: AtmosphericElement

    var body: some View {
        Group {
            switch element.kind {
            case .bird:
                BirdAnnotationView(heading: element.heading)
            case .boat:
                BoatAnnotationView(heading: element.heading)
            case .cloud:
                CloudAnnotationView()
            case .leaf:
                LeafAnnotationView()
            case .plane:
                PlaneAnnotationView(heading: element.heading)
            case .hotAirBalloon:
                HotAirBalloonAnnotationView()
            case .butterfly:
                ButterflyAnnotationView()
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Bird (flapping wings)

private struct BirdAnnotationView: View {
    let heading: Double
    @State private var wingAngle: Double = -15
    @State private var appeared = false

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let flapOffset = wingAngle

            // Draw a flock of 2–3 birds in a V
            for i in 0..<3 {
                let offsetX = Double(i - 1) * 14.0
                let offsetY = abs(Double(i - 1)) * 6.0
                drawFlappingBird(
                    context: ctx,
                    x: cx + offsetX,
                    y: cy + offsetY,
                    wingFlap: flapOffset + Double(i) * 5
                )
            }
        }
        .frame(width: 60, height: 36)
        .rotationEffect(.degrees(heading))
        .opacity(appeared ? 0.7 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) { appeared = true }
            withAnimation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true)) {
                wingAngle = 20
            }
        }
    }

    private func drawFlappingBird(context: GraphicsContext, x: Double, y: Double, wingFlap: Double) {
        // Body dot
        let bodyRect = CGRect(x: x - 2, y: y - 1.5, width: 4, height: 3)
        context.fill(Path(ellipseIn: bodyRect), with: .color(.black.opacity(0.55)))

        // Left wing
        var leftWing = Path()
        leftWing.move(to: CGPoint(x: x - 2, y: y))
        leftWing.addQuadCurve(
            to: CGPoint(x: x - 12, y: y - 1),
            control: CGPoint(x: x - 7, y: y + wingFlap * 0.4 - 6)
        )
        context.stroke(leftWing, with: .color(.black.opacity(0.55)), lineWidth: 1.8)

        // Right wing
        var rightWing = Path()
        rightWing.move(to: CGPoint(x: x + 2, y: y))
        rightWing.addQuadCurve(
            to: CGPoint(x: x + 12, y: y - 1),
            control: CGPoint(x: x + 7, y: y + wingFlap * 0.4 - 6)
        )
        context.stroke(rightWing, with: .color(.black.opacity(0.55)), lineWidth: 1.8)
    }
}

// MARK: - Boat (hull + sail + bobbing wake)

private struct BoatAnnotationView: View {
    let heading: Double
    @State private var bobOffset: CGFloat = 0
    @State private var sailBillow: CGFloat = 0
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Wake lines behind the boat
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(Color.white.opacity(0.3 - Double(i) * 0.08))
                        .frame(width: CGFloat(20 + i * 8), height: 1.5)
                }
            }
            .offset(y: 16)

            // Hull — rounded boat shape
            Canvas { ctx, size in
                let w = size.width
                let h = size.height
                var hull = Path()
                hull.move(to: CGPoint(x: w * 0.1, y: h * 0.55))
                hull.addQuadCurve(to: CGPoint(x: w * 0.9, y: h * 0.55), control: CGPoint(x: w * 0.5, y: h * 0.85))
                hull.addLine(to: CGPoint(x: w * 0.8, y: h * 0.45))
                hull.addLine(to: CGPoint(x: w * 0.2, y: h * 0.45))
                hull.closeSubpath()
                ctx.fill(hull, with: .color(Color(red: 0.55, green: 0.35, blue: 0.2)))

                // Mast
                var mast = Path()
                mast.move(to: CGPoint(x: w * 0.45, y: h * 0.45))
                mast.addLine(to: CGPoint(x: w * 0.45, y: h * 0.08))
                ctx.stroke(mast, with: .color(Color(red: 0.45, green: 0.3, blue: 0.15)), lineWidth: 2)

                // Sail — triangular with a slight curve for billow
                var sail = Path()
                sail.move(to: CGPoint(x: w * 0.47, y: h * 0.1))
                sail.addQuadCurve(
                    to: CGPoint(x: w * 0.47, y: h * 0.42),
                    control: CGPoint(x: w * (0.75 + Double(sailBillow) * 0.05), y: h * 0.25)
                )
                sail.addLine(to: CGPoint(x: w * 0.47, y: h * 0.1))
                ctx.fill(sail, with: .color(.white.opacity(0.85)))
                ctx.stroke(sail, with: .color(.gray.opacity(0.3)), lineWidth: 0.5)
            }
            .frame(width: 44, height: 40)
            .offset(y: bobOffset)
        }
        .frame(width: 50, height: 50)
        .rotationEffect(.degrees(heading))
        .opacity(appeared ? 0.9 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) { appeared = true }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                bobOffset = 3
            }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                sailBillow = 1
            }
        }
    }
}

// MARK: - Cloud (soft, drifting)

private struct CloudAnnotationView: View {
    @State private var appeared = false
    @State private var driftX: CGFloat = 0

    var body: some View {
        CloudShape()
            .fill(Color.white.opacity(0.35))
            .frame(width: CGFloat.random(in: 80...140), height: CGFloat.random(in: 35...55))
            .blur(radius: 3)
            .offset(x: driftX)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.easeIn(duration: 2)) { appeared = true }
                withAnimation(.linear(duration: 60).repeatForever(autoreverses: true)) {
                    driftX = CGFloat.random(in: 15...30)
                }
            }
    }
}

private struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.addEllipse(in: CGRect(x: w * 0.05, y: h * 0.30, width: w * 0.40, height: h * 0.70))
        path.addEllipse(in: CGRect(x: w * 0.25, y: h * 0.05, width: w * 0.50, height: h * 0.70))
        path.addEllipse(in: CGRect(x: w * 0.50, y: h * 0.20, width: w * 0.42, height: h * 0.65))
        path.addEllipse(in: CGRect(x: w * 0.70, y: h * 0.35, width: w * 0.28, height: h * 0.50))
        return path
    }
}

// MARK: - Leaf (detailed shape with veins, tumbling)

private struct LeafAnnotationView: View {
    @State private var rotation: Double = Double.random(in: 0...360)
    @State private var swayX: CGFloat = 0
    @State private var swayY: CGFloat = 0
    @State private var appeared = false

    private let leafColor: Color = {
        let colors: [Color] = [
            Color(red: 0.2, green: 0.7, blue: 0.3, opacity: 0.75),
            Color(red: 0.85, green: 0.7, blue: 0.1, opacity: 0.7),
            Color(red: 0.8, green: 0.4, blue: 0.1, opacity: 0.7),
            Color(red: 0.75, green: 0.15, blue: 0.15, opacity: 0.65),
            Color(red: 0.6, green: 0.5, blue: 0.05, opacity: 0.7),
        ]
        return colors.randomElement()!
    }()

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height

            // Leaf body — pointed oval
            var leaf = Path()
            leaf.move(to: CGPoint(x: w * 0.5, y: 0))
            leaf.addQuadCurve(to: CGPoint(x: w, y: h * 0.5), control: CGPoint(x: w * 0.95, y: h * 0.05))
            leaf.addQuadCurve(to: CGPoint(x: w * 0.5, y: h), control: CGPoint(x: w * 0.95, y: h * 0.95))
            leaf.addQuadCurve(to: CGPoint(x: 0, y: h * 0.5), control: CGPoint(x: w * 0.05, y: h * 0.95))
            leaf.addQuadCurve(to: CGPoint(x: w * 0.5, y: 0), control: CGPoint(x: w * 0.05, y: h * 0.05))
            ctx.fill(leaf, with: .color(leafColor))

            // Center vein
            var vein = Path()
            vein.move(to: CGPoint(x: w * 0.5, y: h * 0.05))
            vein.addLine(to: CGPoint(x: w * 0.5, y: h * 0.95))
            ctx.stroke(vein, with: .color(leafColor.opacity(0.5)), lineWidth: 0.8)

            // Side veins
            for i in 1...3 {
                let t = CGFloat(i) / 4.0
                let cy = h * t

                var leftVein = Path()
                leftVein.move(to: CGPoint(x: w * 0.5, y: cy))
                leftVein.addLine(to: CGPoint(x: w * 0.15, y: cy - h * 0.08))
                ctx.stroke(leftVein, with: .color(leafColor.opacity(0.35)), lineWidth: 0.5)

                var rightVein = Path()
                rightVein.move(to: CGPoint(x: w * 0.5, y: cy))
                rightVein.addLine(to: CGPoint(x: w * 0.85, y: cy - h * 0.08))
                ctx.stroke(rightVein, with: .color(leafColor.opacity(0.35)), lineWidth: 0.5)
            }
        }
        .frame(width: 18, height: 14)
        .rotationEffect(.degrees(rotation))
        .offset(x: swayX, y: swayY)
        .opacity(appeared ? 0.85 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) { appeared = true }
            withAnimation(.linear(duration: Double.random(in: 4...8)).repeatForever(autoreverses: false)) {
                rotation += 360
            }
            withAnimation(.easeInOut(duration: Double.random(in: 1.5...3)).repeatForever(autoreverses: true)) {
                swayX = CGFloat.random(in: -8...8)
                swayY = CGFloat.random(in: -5...5)
            }
        }
    }
}

// MARK: - Plane (takes off from airports, detailed silhouette)

private struct PlaneAnnotationView: View {
    let heading: Double
    @State private var appeared = false
    @State private var altitude: CGFloat = 0

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height

            // Fuselage
            var fuselage = Path()
            fuselage.move(to: CGPoint(x: w * 0.5, y: h * 0.05))
            fuselage.addQuadCurve(to: CGPoint(x: w * 0.55, y: h * 0.85), control: CGPoint(x: w * 0.56, y: h * 0.4))
            fuselage.addLine(to: CGPoint(x: w * 0.5, y: h * 0.95))
            fuselage.addLine(to: CGPoint(x: w * 0.45, y: h * 0.85))
            fuselage.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.05), control: CGPoint(x: w * 0.44, y: h * 0.4))
            ctx.fill(fuselage, with: .color(.white.opacity(0.9)))
            ctx.stroke(fuselage, with: .color(.gray.opacity(0.3)), lineWidth: 0.5)

            // Main wings
            var leftWing = Path()
            leftWing.move(to: CGPoint(x: w * 0.48, y: h * 0.38))
            leftWing.addLine(to: CGPoint(x: w * 0.05, y: h * 0.45))
            leftWing.addLine(to: CGPoint(x: w * 0.05, y: h * 0.48))
            leftWing.addLine(to: CGPoint(x: w * 0.48, y: h * 0.44))
            leftWing.closeSubpath()
            ctx.fill(leftWing, with: .color(.white.opacity(0.85)))
            ctx.stroke(leftWing, with: .color(.gray.opacity(0.3)), lineWidth: 0.5)

            var rightWing = Path()
            rightWing.move(to: CGPoint(x: w * 0.52, y: h * 0.38))
            rightWing.addLine(to: CGPoint(x: w * 0.95, y: h * 0.45))
            rightWing.addLine(to: CGPoint(x: w * 0.95, y: h * 0.48))
            rightWing.addLine(to: CGPoint(x: w * 0.52, y: h * 0.44))
            rightWing.closeSubpath()
            ctx.fill(rightWing, with: .color(.white.opacity(0.85)))
            ctx.stroke(rightWing, with: .color(.gray.opacity(0.3)), lineWidth: 0.5)

            // Tail fin
            var tail = Path()
            tail.move(to: CGPoint(x: w * 0.48, y: h * 0.78))
            tail.addLine(to: CGPoint(x: w * 0.3, y: h * 0.85))
            tail.addLine(to: CGPoint(x: w * 0.3, y: h * 0.87))
            tail.addLine(to: CGPoint(x: w * 0.48, y: h * 0.82))
            tail.closeSubpath()
            ctx.fill(tail, with: .color(.white.opacity(0.8)))

            var tailR = Path()
            tailR.move(to: CGPoint(x: w * 0.52, y: h * 0.78))
            tailR.addLine(to: CGPoint(x: w * 0.7, y: h * 0.85))
            tailR.addLine(to: CGPoint(x: w * 0.7, y: h * 0.87))
            tailR.addLine(to: CGPoint(x: w * 0.52, y: h * 0.82))
            tailR.closeSubpath()
            ctx.fill(tailR, with: .color(.white.opacity(0.8)))

            // Engine pods
            for xMul in [0.3, 0.7] {
                let ex = w * xMul
                let ey = h * 0.42
                let engineRect = CGRect(x: ex - 3, y: ey - 2, width: 6, height: 8)
                ctx.fill(Path(roundedRect: engineRect, cornerRadius: 2), with: .color(.gray.opacity(0.5)))
            }
        }
        .frame(width: 40, height: 48)
        .shadow(color: .black.opacity(0.15), radius: 6 + altitude * 0.5, x: 2 + altitude * 0.3, y: 4 + altitude * 0.5)
        .rotationEffect(.degrees(heading))
        .opacity(appeared ? 0.85 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) { appeared = true }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                altitude = 6
            }
        }
    }
}

// MARK: - Hot Air Balloon

private struct HotAirBalloonAnnotationView: View {
    @State private var appeared = false
    @State private var bobY: CGFloat = 0

    private let balloonColor: Color = {
        let colors: [Color] = [.red, .orange, .blue, .purple, .green, .yellow]
        return colors.randomElement()!
    }()

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height

            // Balloon envelope
            var envelope = Path()
            envelope.addEllipse(in: CGRect(x: w * 0.15, y: 0, width: w * 0.7, height: h * 0.65))
            ctx.fill(envelope, with: .color(balloonColor.opacity(0.75)))

            // Stripes on envelope
            for i in 0..<3 {
                let stripX = w * (0.25 + Double(i) * 0.15)
                var stripe = Path()
                stripe.move(to: CGPoint(x: stripX, y: h * 0.05))
                stripe.addQuadCurve(
                    to: CGPoint(x: stripX + w * 0.02, y: h * 0.6),
                    control: CGPoint(x: stripX + w * 0.08, y: h * 0.3)
                )
                ctx.stroke(stripe, with: .color(.white.opacity(0.4)), lineWidth: 2)
            }

            // Basket ropes
            for xMul in [0.35, 0.65] {
                var rope = Path()
                rope.move(to: CGPoint(x: w * xMul, y: h * 0.6))
                rope.addLine(to: CGPoint(x: w * (xMul < 0.5 ? 0.4 : 0.6), y: h * 0.78))
                ctx.stroke(rope, with: .color(.brown.opacity(0.5)), lineWidth: 0.8)
            }

            // Basket
            let basketRect = CGRect(x: w * 0.35, y: h * 0.78, width: w * 0.3, height: h * 0.15)
            ctx.fill(Path(roundedRect: basketRect, cornerRadius: 2), with: .color(Color(red: 0.55, green: 0.35, blue: 0.15)))
        }
        .frame(width: 36, height: 48)
        .offset(y: bobY)
        .opacity(appeared ? 0.8 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) { appeared = true }
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                bobY = -5
            }
        }
    }
}

// MARK: - Butterfly (fluttering wings)

private struct ButterflyAnnotationView: View {
    @State private var wingSpread: Double = 0
    @State private var flutterX: CGFloat = 0
    @State private var flutterY: CGFloat = 0
    @State private var appeared = false

    private let wingColor: Color = {
        let colors: [Color] = [
            Color(red: 1.0, green: 0.5, blue: 0.2), // Monarch
            Color(red: 0.3, green: 0.5, blue: 1.0), // Blue morpho
            Color(red: 1.0, green: 1.0, blue: 0.3), // Swallowtail
            Color(red: 0.9, green: 0.2, blue: 0.5), // Pink
        ]
        return colors.randomElement()!
    }()

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let spread = 0.6 + wingSpread * 0.4

            // Left wings
            var leftUpper = Path()
            leftUpper.addEllipse(in: CGRect(
                x: cx - 10 * spread, y: cy - 7,
                width: 9 * spread, height: 8
            ))
            ctx.fill(leftUpper, with: .color(wingColor.opacity(0.8)))

            var leftLower = Path()
            leftLower.addEllipse(in: CGRect(
                x: cx - 8 * spread, y: cy - 1,
                width: 7 * spread, height: 6
            ))
            ctx.fill(leftLower, with: .color(wingColor.opacity(0.65)))

            // Right wings
            var rightUpper = Path()
            rightUpper.addEllipse(in: CGRect(
                x: cx + 1, y: cy - 7,
                width: 9 * spread, height: 8
            ))
            ctx.fill(rightUpper, with: .color(wingColor.opacity(0.8)))

            var rightLower = Path()
            rightLower.addEllipse(in: CGRect(
                x: cx + 1, y: cy - 1,
                width: 7 * spread, height: 6
            ))
            ctx.fill(rightLower, with: .color(wingColor.opacity(0.65)))

            // Body
            let bodyRect = CGRect(x: cx - 1, y: cy - 5, width: 2, height: 10)
            ctx.fill(Path(ellipseIn: bodyRect), with: .color(.black.opacity(0.6)))

            // Antennae
            var antenna1 = Path()
            antenna1.move(to: CGPoint(x: cx - 1, y: cy - 5))
            antenna1.addLine(to: CGPoint(x: cx - 4, y: cy - 9))
            ctx.stroke(antenna1, with: .color(.black.opacity(0.4)), lineWidth: 0.5)

            var antenna2 = Path()
            antenna2.move(to: CGPoint(x: cx + 1, y: cy - 5))
            antenna2.addLine(to: CGPoint(x: cx + 4, y: cy - 9))
            ctx.stroke(antenna2, with: .color(.black.opacity(0.4)), lineWidth: 0.5)
        }
        .frame(width: 24, height: 20)
        .offset(x: flutterX, y: flutterY)
        .opacity(appeared ? 0.85 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) { appeared = true }
            withAnimation(.easeInOut(duration: 0.2).repeatForever(autoreverses: true)) {
                wingSpread = 1
            }
            withAnimation(.easeInOut(duration: Double.random(in: 1.5...3)).repeatForever(autoreverses: true)) {
                flutterX = CGFloat.random(in: -10...10)
                flutterY = CGFloat.random(in: -6...6)
            }
        }
    }
}
