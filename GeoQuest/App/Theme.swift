import SwiftUI

enum GQTheme {
    // MARK: - Colors
    static let primary = Color.blue
    static let secondary = Color.indigo
    static let accent = Color.orange
    static let background = Color(.systemBackground)
    static let cardBackground = Color(.secondarySystemBackground)
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red

    // Quest difficulty colors
    static let easyColor = Color.green
    static let mediumColor = Color.yellow
    static let hardColor = Color.orange
    static let expertColor = Color.red

    // MARK: - Fonts
    static let titleFont: Font = .system(.title, design: .rounded, weight: .bold)
    static let title2Font: Font = .system(.title2, design: .rounded, weight: .bold)
    static let title3Font: Font = .system(.title3, design: .rounded, weight: .semibold)
    static let headlineFont: Font = .system(.headline, design: .rounded, weight: .semibold)
    static let bodyFont: Font = .system(.body, design: .rounded)
    static let captionFont: Font = .system(.caption, design: .rounded)
    static let caption2Font: Font = .system(.caption2, design: .rounded)

    // MARK: - Animations
    static let bouncy: Animation = .bouncy(duration: 0.4, extraBounce: 0.15)
    static let bouncyQuick: Animation = .bouncy(duration: 0.25, extraBounce: 0.1)
    static let smooth: Animation = .smooth(duration: 0.3)
    static let spring: Animation = .spring(response: 0.4, dampingFraction: 0.7)

    // MARK: - Spacing
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24
    static let paddingXLarge: CGFloat = 32

    // MARK: - Sizing
    static let cornerRadius: CGFloat = 16
    static let cornerRadiusSmall: CGFloat = 10
    static let cornerRadiusLarge: CGFloat = 24
    static let iconSizeSmall: CGFloat = 20
    static let iconSizeMedium: CGFloat = 28
    static let iconSizeLarge: CGFloat = 44
    static let buttonHeight: CGFloat = 50
}
