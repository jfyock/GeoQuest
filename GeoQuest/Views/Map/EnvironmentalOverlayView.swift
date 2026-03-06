import SwiftUI

// MARK: - Environmental Overlay

/// A full-screen overlay that spawns drifting atmospheric elements (birds, boats, clouds, leaves)
/// to make the game world feel alive. All animations loop endlessly without any timers; each
/// element schedules its own respawn via recursive async tasks so the view stays lightweight.
struct EnvironmentalOverlayView: View {
    // Number of concurrent instances of each element type
    private let birdCount = 4
    private let boatCount = 2
    private let cloudCount = 3
    private let leafCount = 5

    var body: some View {
        ZStack {
            ForEach(0..<birdCount, id: \.self) { i in
                FloatingBirdView(index: i)
            }
            ForEach(0..<boatCount, id: \.self) { i in
                FloatingBoatView(index: i)
            }
            ForEach(0..<cloudCount, id: \.self) { i in
                FloatingCloudView(index: i)
            }
            ForEach(0..<leafCount, id: \.self) { i in
                DriftingLeafView(index: i)
            }
        }
        .allowsHitTesting(false) // Never intercept map touches
        .ignoresSafeArea()
    }
}

// MARK: - Shared helpers

private func staggeredDelay(index: Int, period: Double) -> Double {
    Double(index) * (period / 4.0)
}

// MARK: - Birds

/// A flock of 1–3 birds that sweeps across the screen in a gentle V formation.
private struct FloatingBirdView: View {
    let index: Int

    @State private var isVisible = false
    @State private var xOffset: CGFloat = -120
    @State private var yPos: CGFloat = 0
    @State private var wingPhase: Double = 0
    @State private var flapAngle: Double = 0

    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height

    var body: some View {
        Canvas { ctx, size in
            // Draw 1–3 birds in a loose V shape
            let birdCount = (index % 3) + 1
            for b in 0..<birdCount {
                let bx = Double(b) * 18.0
                let by = abs(Double(b) - Double(birdCount) / 2.0) * 8.0
                let wing = sin(wingPhase + Double(b) * 0.6) * 5.0
                drawBirdGlyph(context: ctx, x: bx + 10, y: by + 14 + wing)
            }
        }
        .frame(width: 80, height: 40)
        .opacity(isVisible ? 0.55 : 0)
        .position(x: xOffset, y: yPos)
        .onAppear {
            startCycle()
        }
        .onChange(of: xOffset) { _, new in
            // Continuous wing flap via recursive display-link–style animation
        }
    }

    private func drawBirdGlyph(context: GraphicsContext, x: Double, y: Double) {
        var path = Path()
        // Simple M-shape bird silhouette
        path.move(to: CGPoint(x: x - 10, y: y))
        path.addQuadCurve(to: CGPoint(x: x, y: y - 5), control: CGPoint(x: x - 5, y: y - 7))
        path.addQuadCurve(to: CGPoint(x: x + 10, y: y), control: CGPoint(x: x + 5, y: y - 7))
        context.stroke(path, with: .color(.black.opacity(0.45)), lineWidth: 1.5)
    }

    private func startCycle() {
        let delay = staggeredDelay(index: index, period: 22)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let newY = CGFloat.random(in: screenHeight * 0.08...screenHeight * 0.40)
            let duration = Double.random(in: 14...22)

            xOffset = -80
            yPos = newY
            isVisible = false

            withAnimation(.linear(duration: 0.3)) { isVisible = true }

            // Wing flapping
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                wingPhase = .pi
            }

            // Fly across screen
            withAnimation(.linear(duration: duration)) {
                xOffset = screenWidth + 120
            }

            // Fade out near end and respawn
            DispatchQueue.main.asyncAfter(deadline: .now() + duration - 1.5) {
                withAnimation(.linear(duration: 1.5)) { isVisible = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 6...18)) {
                    startCycle()
                }
            }
        }
    }
}

// MARK: - Boats

/// A small boat silhouette that drifts slowly across the lower third of the screen,
/// simulating watercraft on a nearby body of water.
private struct FloatingBoatView: View {
    let index: Int

    @State private var isVisible = false
    @State private var xOffset: CGFloat = 0
    @State private var yPos: CGFloat = 0
    @State private var bobOffset: CGFloat = 0

    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height

    var body: some View {
        ZStack {
            // Hull
            Capsule()
                .fill(Color.brown.opacity(0.65))
                .frame(width: 52, height: 14)
                .offset(y: 8)

            // Mast
            Rectangle()
                .fill(Color.brown.opacity(0.55))
                .frame(width: 2, height: 28)
                .offset(x: -4, y: -6)

            // Sail
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: -24))
                path.addLine(to: CGPoint(x: 18, y: -8))
                path.closeSubpath()
            }
            .fill(Color.white.opacity(0.70))
            .offset(x: -5, y: -6)

            // Wake lines (tiny horizontal strokes)
            VStack(spacing: 3) {
                ForEach(0..<2, id: \.self) { _ in
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: CGFloat.random(in: 28...46), height: 2)
                }
            }
            .offset(y: 20)
        }
        .frame(width: 70, height: 60)
        .opacity(isVisible ? 1 : 0)
        .offset(y: bobOffset)
        .position(x: xOffset, y: yPos)
        .onAppear { startCycle() }
    }

    private func startCycle() {
        let delay = staggeredDelay(index: index, period: 40) + Double(index) * 12
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let newY = CGFloat.random(in: screenHeight * 0.60...screenHeight * 0.88)
            let duration = Double.random(in: 30...50)
            let rightToLeft = index % 2 == 0

            xOffset = rightToLeft ? screenWidth + 60 : -60
            yPos = newY
            isVisible = false

            withAnimation(.easeIn(duration: 1.0)) { isVisible = true }

            // Gentle bobbing
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                bobOffset = 4
            }

            // Drift across
            withAnimation(.linear(duration: duration)) {
                xOffset = rightToLeft ? -80 : screenWidth + 80
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + duration - 2) {
                withAnimation(.easeOut(duration: 2)) { isVisible = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 15...40)) {
                    startCycle()
                }
            }
        }
    }
}

// MARK: - Clouds

/// A softly drifting cloud shape that floats across the top portion of the screen.
private struct FloatingCloudView: View {
    let index: Int

    @State private var isVisible = false
    @State private var xOffset: CGFloat = 0
    @State private var yPos: CGFloat = 0

    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height

    var body: some View {
        CloudShape()
            .fill(Color.white.opacity(0.22))
            .frame(
                width: CGFloat(80 + (index * 30) % 70),
                height: CGFloat(36 + (index * 12) % 24)
            )
            .blur(radius: 2)
            .opacity(isVisible ? 1 : 0)
            .position(x: xOffset, y: yPos)
            .onAppear { startCycle() }
    }

    private func startCycle() {
        let delay = staggeredDelay(index: index, period: 35)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let newY = CGFloat.random(in: screenHeight * 0.03...screenHeight * 0.20)
            let duration = Double.random(in: 50...90)

            xOffset = -150
            yPos = newY

            withAnimation(.easeIn(duration: 4)) { isVisible = true }
            withAnimation(.linear(duration: duration)) { xOffset = screenWidth + 160 }

            DispatchQueue.main.asyncAfter(deadline: .now() + duration - 6) {
                withAnimation(.easeOut(duration: 6)) { isVisible = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 10...30)) {
                    startCycle()
                }
            }
        }
    }
}

private struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.addEllipse(in: CGRect(x: w * 0.10, y: h * 0.30, width: w * 0.40, height: h * 0.70))
        path.addEllipse(in: CGRect(x: w * 0.30, y: h * 0.05, width: w * 0.50, height: h * 0.70))
        path.addEllipse(in: CGRect(x: w * 0.55, y: h * 0.25, width: w * 0.38, height: h * 0.60))
        return path
    }
}

// MARK: - Leaves

/// A single leaf that spirals and tumbles across the screen as if blown by wind.
private struct DriftingLeafView: View {
    let index: Int

    @State private var isVisible = false
    @State private var xPos: CGFloat = 0
    @State private var yPos: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var swayOffset: CGFloat = 0

    private let screenWidth = UIScreen.main.bounds.width
    private let screenHeight = UIScreen.main.bounds.height

    private var leafColor: Color {
        let colors: [Color] = [
            .green.opacity(0.65), .yellow.opacity(0.60),
            Color(red: 0.8, green: 0.4, blue: 0.1).opacity(0.65),
            Color(red: 0.9, green: 0.6, blue: 0.1).opacity(0.60),
            .red.opacity(0.55),
        ]
        return colors[index % colors.count]
    }

    var body: some View {
        LeafShape()
            .fill(leafColor)
            .frame(width: 14, height: 10)
            .rotationEffect(.degrees(rotation))
            .opacity(isVisible ? 0.8 : 0)
            .position(x: xPos + swayOffset, y: yPos)
            .onAppear { startCycle() }
    }

    private func startCycle() {
        let delay = Double(index) * 3.5 + Double.random(in: 0...4)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let startX = CGFloat.random(in: 0...screenWidth)
            let startY = CGFloat.random(in: -20...screenHeight * 0.3)
            let fallDuration = Double.random(in: 8...16)

            xPos = startX
            yPos = startY
            rotation = Double.random(in: 0...360)
            isVisible = false

            withAnimation(.easeIn(duration: 0.5)) { isVisible = true }

            withAnimation(.linear(duration: fallDuration)) {
                yPos = screenHeight + 30
            }
            withAnimation(.linear(duration: fallDuration).repeatForever(autoreverses: false)) {
                rotation += Double.random(in: 180...540)
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                swayOffset = CGFloat.random(in: -25...25)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + fallDuration - 1.0) {
                withAnimation(.easeOut(duration: 1.0)) { isVisible = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2...10)) {
                    startCycle()
                }
            }
        }
    }
}

private struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addQuadCurve(to: CGPoint(x: w, y: h * 0.5), control: CGPoint(x: w * 1.1, y: 0))
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: h), control: CGPoint(x: w * 1.1, y: h))
        path.addQuadCurve(to: CGPoint(x: 0, y: h * 0.5), control: CGPoint(x: -w * 0.1, y: h))
        path.addQuadCurve(to: CGPoint(x: w * 0.5, y: 0), control: CGPoint(x: -w * 0.1, y: 0))
        // Centre vein
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addLine(to: CGPoint(x: w * 0.5, y: h))
        return path
    }
}
