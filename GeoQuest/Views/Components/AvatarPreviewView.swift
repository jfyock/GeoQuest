import SwiftUI

/// Displays the player's avatar at a given size.
///
/// **3D mode** — active when `avatar_body_default.glb` is present in the bundle.
/// Renders a SceneKit scene composed of the body mesh (tinted with the chosen body
/// colour) and the selected accessory mesh, clipped to a circle.
///
/// **2D fallback** — used when GLB assets are not yet added to the project.
/// Draws the same design as before (coloured circles, SF Symbol accessories, etc.)
/// so the app works correctly at every stage of asset integration.
struct AvatarPreviewView: View {
    let config: AvatarConfig
    var size: CGFloat = AppConstants.avatarDefaultSize
    /// Spin the avatar continuously — enable on the customisation screen.
    var autoRotate: Bool = false

    private var has3DBody: Bool {
        // Only render a RealityView at sizes where 3D detail is actually visible.
        // Below 80 pt the model is too small to benefit and each instance adds GPU overhead.
        let sizeOk = size >= 80
        let available = GLBAssetLoader.shared.isAvailable(named: "avatar_body_default")
        print("[AvatarPreviewView] has3DBody: size=\(size) sizeOk=\(sizeOk) glbAvailable=\(available) → \(sizeOk && available ? "3D" : "2D")")
        return sizeOk && available
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColorValue)
                .frame(width: size, height: size)

            if has3DBody {
                AvatarSceneView(config: config, autoRotate: autoRotate, cameraZ: 2.5)
                    .frame(width: size * 0.88, height: size * 0.88)
                    .clipShape(Circle())
                    .overlay(alignment: .bottom) {
                        // Debug overlay — remove once 3D is confirmed working
                        Text("3D")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.yellow)
                            .padding(2)
                    }
            } else {
                // 2D fallback — identical to the previous implementation
                Circle()
                    .fill(bodyColorValue)
                    .frame(width: size * 0.75, height: size * 0.75)

                eyesView
                    .offset(y: -size * 0.06)

                mouthView
                    .offset(y: size * 0.12)

                accessoryView
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Body / Background Colours

    private var bodyColorValue: Color {
        switch config.bodyColor {
        case .red:    return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green:  return .green
        case .blue:   return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink:   return .pink
        case .teal:   return .teal
        case .mint:   return .mint
        case .cyan:   return .cyan
        case .brown:  return .brown
        }
    }

    private var backgroundColorValue: Color {
        switch config.backgroundColor {
        case .lightBlue:   return Color.blue.opacity(0.2)
        case .lightGreen:  return Color.green.opacity(0.2)
        case .lightPink:   return Color.pink.opacity(0.2)
        case .lightYellow: return Color.yellow.opacity(0.2)
        case .lightPurple: return Color.purple.opacity(0.2)
        case .lightOrange: return Color.orange.opacity(0.2)
        case .lightGray:   return Color.gray.opacity(0.2)
        case .white:       return Color.white
        }
    }

    // MARK: - Eyes (2D fallback)

    @ViewBuilder
    private var eyesView: some View {
        let eyeSize = size * 0.1
        let spacing = size * 0.18
        HStack(spacing: spacing) {
            switch config.eyeStyle {
            case .normal:
                Circle().fill(.white).frame(width: eyeSize, height: eyeSize)
                Circle().fill(.white).frame(width: eyeSize, height: eyeSize)
            case .happy:
                Text("^").font(.system(size: eyeSize * 1.5, weight: .bold)).foregroundStyle(.white)
                Text("^").font(.system(size: eyeSize * 1.5, weight: .bold)).foregroundStyle(.white)
            case .cool:
                Rectangle().fill(.white).frame(width: eyeSize * 1.3, height: eyeSize * 0.5).clipShape(Capsule())
                Rectangle().fill(.white).frame(width: eyeSize * 1.3, height: eyeSize * 0.5).clipShape(Capsule())
            case .surprised:
                Circle().fill(.white).frame(width: eyeSize * 1.3, height: eyeSize * 1.3)
                Circle().fill(.white).frame(width: eyeSize * 1.3, height: eyeSize * 1.3)
            case .sleepy:
                Capsule().fill(.white).frame(width: eyeSize * 1.2, height: eyeSize * 0.4)
                Capsule().fill(.white).frame(width: eyeSize * 1.2, height: eyeSize * 0.4)
            case .wink:
                Circle().fill(.white).frame(width: eyeSize, height: eyeSize)
                Text("-").font(.system(size: eyeSize * 2, weight: .bold)).foregroundStyle(.white)
            case .stars:
                Image(systemName: "star.fill").font(.system(size: eyeSize)).foregroundStyle(.white)
                Image(systemName: "star.fill").font(.system(size: eyeSize)).foregroundStyle(.white)
            case .hearts:
                Image(systemName: "heart.fill").font(.system(size: eyeSize)).foregroundStyle(.white)
                Image(systemName: "heart.fill").font(.system(size: eyeSize)).foregroundStyle(.white)
            }
        }
    }

    // MARK: - Mouth (2D fallback)

    @ViewBuilder
    private var mouthView: some View {
        let mouthSize = size * 0.12
        switch config.mouthStyle {
        case .smile:
            Capsule().fill(.white).frame(width: mouthSize * 2, height: mouthSize * 0.6)
        case .grin:
            Capsule().fill(.white).frame(width: mouthSize * 2.5, height: mouthSize * 0.8)
        case .neutral:
            Rectangle().fill(.white).frame(width: mouthSize * 1.5, height: mouthSize * 0.3)
        case .open:
            Circle().fill(.white).frame(width: mouthSize, height: mouthSize)
        case .tongue:
            VStack(spacing: 0) {
                Capsule().fill(.white).frame(width: mouthSize * 2, height: mouthSize * 0.5)
                Circle().fill(Color.pink.opacity(0.8)).frame(width: mouthSize * 0.6, height: mouthSize * 0.6)
                    .offset(y: -2)
            }
        case .cat:
            Text("w").font(.system(size: mouthSize * 1.5, weight: .bold)).foregroundStyle(.white)
        case .smirk:
            Capsule().fill(.white).frame(width: mouthSize * 1.5, height: mouthSize * 0.5)
                .offset(x: mouthSize * 0.3)
        }
    }

    // MARK: - Accessory (2D fallback)

    @ViewBuilder
    private var accessoryView: some View {
        let accSize = size * 0.3
        switch config.accessory {
        case .none:
            EmptyView()
        case .hat:
            Image(systemName: "graduationcap.fill")
                .font(.system(size: accSize))
                .foregroundStyle(.white.opacity(0.9))
                .offset(y: -size * 0.35)
        case .crown:
            Image(systemName: "crown.fill")
                .font(.system(size: accSize))
                .foregroundStyle(.yellow)
                .offset(y: -size * 0.35)
        case .glasses:
            Image(systemName: "eyeglasses")
                .font(.system(size: accSize * 0.8))
                .foregroundStyle(.white.opacity(0.9))
                .offset(y: -size * 0.04)
        case .sunglasses:
            Image(systemName: "sunglasses.fill")
                .font(.system(size: accSize * 0.8))
                .foregroundStyle(.white.opacity(0.9))
                .offset(y: -size * 0.04)
        case .headband:
            Capsule()
                .fill(.white.opacity(0.6))
                .frame(width: size * 0.8, height: size * 0.06)
                .offset(y: -size * 0.25)
        case .antenna:
            VStack(spacing: 0) {
                Circle().fill(.yellow).frame(width: size * 0.08, height: size * 0.08)
                Rectangle().fill(.white.opacity(0.7)).frame(width: 2, height: size * 0.15)
            }
            .offset(y: -size * 0.42)
        case .bow:
            Image(systemName: "gift.fill")
                .font(.system(size: accSize * 0.6))
                .foregroundStyle(.pink)
                .offset(x: size * 0.25, y: -size * 0.25)
        }
    }
}
