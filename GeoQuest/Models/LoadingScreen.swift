import SwiftUI

/// Each loading screen uses a background image from Assets.xcassets.
///
/// **Naming convention for background images:**
///   `loading_bg_0`, `loading_bg_1`, `loading_bg_2`, `loading_bg_3`, `loading_bg_4`
///
/// Add images to `Assets.xcassets` with those exact names.
/// Recommended size: 1290x2796px (iPhone 15 Pro Max) or similar.
/// Use colorful, cartoony landscape / adventure illustrations.
struct LoadingScreenData: Identifiable, Sendable {
    let id: Int
    let title: String
    let subtitle: String
    let iconName: String
    let backgroundColor: Color
    /// Name of the image asset in Assets.xcassets (e.g. "loading_bg_0")
    let backgroundImageName: String

    static let presets: [LoadingScreenData] = [
        LoadingScreenData(
            id: 0,
            title: "Discovering Quests...",
            subtitle: "Adventures await around every corner",
            iconName: "map.fill",
            backgroundColor: .teal,
            backgroundImageName: "loading_bg_0"
        ),
        LoadingScreenData(
            id: 1,
            title: "Loading the World...",
            subtitle: "Millions of quests to explore",
            iconName: "globe.americas.fill",
            backgroundColor: .indigo,
            backgroundImageName: "loading_bg_1"
        ),
        LoadingScreenData(
            id: 2,
            title: "Preparing Your Adventure...",
            subtitle: "Get ready to explore the unknown",
            iconName: "figure.walk",
            backgroundColor: .orange,
            backgroundImageName: "loading_bg_2"
        ),
        LoadingScreenData(
            id: 3,
            title: "Connecting Explorers...",
            subtitle: "Join the global quest community",
            iconName: "person.3.fill",
            backgroundColor: .purple,
            backgroundImageName: "loading_bg_3"
        ),
        LoadingScreenData(
            id: 4,
            title: "Charting New Paths...",
            subtitle: "Your next discovery is just steps away",
            iconName: "location.north.fill",
            backgroundColor: .blue,
            backgroundImageName: "loading_bg_4"
        ),
    ]
}
