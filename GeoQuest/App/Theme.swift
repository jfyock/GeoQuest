import SwiftUI

enum GQTheme {
    // MARK: - Cartoony Color Palette (Fortnite / Clash Royale inspired)
    static let primary = Color(hex: "4A90FF")       // Vibrant blue
    static let secondary = Color(hex: "7B5CFF")     // Electric purple
    static let accent = Color(hex: "FF8A34")         // Hot orange
    static let background = Color(.systemBackground)
    static let cardBackground = Color(.secondarySystemBackground)
    static let success = Color(hex: "3DD97A")        // Neon green
    static let warning = Color(hex: "FFB938")        // Gold yellow
    static let error = Color(hex: "FF4757")          // Punchy red

    // Cartoony gradient pairs
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "4A90FF"), Color(hex: "7B5CFF")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "FF8A34"), Color(hex: "FF5E62")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let successGradient = LinearGradient(
        colors: [Color(hex: "3DD97A"), Color(hex: "20C997")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let funGradient = LinearGradient(
        colors: [Color(hex: "FF6B6B"), Color(hex: "FFD93D"), Color(hex: "6BCB77"), Color(hex: "4D96FF")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let menuGradient = LinearGradient(
        colors: [Color(hex: "667EEA"), Color(hex: "764BA2")],
        startPoint: .top, endPoint: .bottom
    )

    // Quest difficulty colors
    static let easyColor = Color(hex: "3DD97A")
    static let mediumColor = Color(hex: "FFB938")
    static let hardColor = Color(hex: "FF8A34")
    static let expertColor = Color(hex: "FF4757")

    // Extra cartoon palette
    static let teal = Color(hex: "00D2D3")
    static let pink = Color(hex: "FF6B81")
    static let lime = Color(hex: "A3CB38")
    static let gold = Color(hex: "FFC312")

    // MARK: - Fonts (rounded for cartoony feel)
    static let titleFont: Font = .system(.title, design: .rounded, weight: .heavy)
    static let title2Font: Font = .system(.title2, design: .rounded, weight: .bold)
    static let title3Font: Font = .system(.title3, design: .rounded, weight: .bold)
    static let headlineFont: Font = .system(.headline, design: .rounded, weight: .bold)
    static let bodyFont: Font = .system(.body, design: .rounded, weight: .medium)
    static let captionFont: Font = .system(.caption, design: .rounded, weight: .medium)
    static let caption2Font: Font = .system(.caption2, design: .rounded, weight: .medium)

    // MARK: - Animations (extra bouncy for cartoony feel)
    static let bouncy: Animation = .bouncy(duration: 0.5, extraBounce: 0.25)
    static let bouncyQuick: Animation = .bouncy(duration: 0.3, extraBounce: 0.2)
    static let bouncyHeavy: Animation = .bouncy(duration: 0.6, extraBounce: 0.35)
    static let smooth: Animation = .smooth(duration: 0.3)
    static let spring: Animation = .spring(response: 0.35, dampingFraction: 0.6)
    static let popIn: Animation = .spring(response: 0.4, dampingFraction: 0.55, blendDuration: 0.1)
    static let wiggle: Animation = .spring(response: 0.3, dampingFraction: 0.4)

    // MARK: - Spacing
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    static let paddingXLarge: CGFloat = 32

    // MARK: - Sizing
    static let cornerRadius: CGFloat = 18
    static let cornerRadiusSmall: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 28
    static let iconSizeSmall: CGFloat = 22
    static let iconSizeMedium: CGFloat = 30
    static let iconSizeLarge: CGFloat = 48
    static let buttonHeight: CGFloat = 58
    static let inputHeight: CGFloat = 56

    // 3D button constants
    static let button3DBorderWidth: CGFloat = 4
    static let button3DEdgeHeight: CGFloat = 6

    // MARK: - Shadows
    static func cartoonShadow(color: Color = .black, opacity: Double = 0.15, radius: CGFloat = 12, y: CGFloat = 6) -> some View {
        Color.clear
            .shadow(color: color.opacity(opacity), radius: radius, x: 0, y: y)
    }
}
