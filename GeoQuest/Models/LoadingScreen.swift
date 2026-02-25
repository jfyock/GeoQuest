import SwiftUI

struct LoadingScreenData: Identifiable, Sendable {
    let id: Int
    let title: String
    let subtitle: String
    let iconName: String
    let backgroundColor: Color

    static let presets: [LoadingScreenData] = [
        LoadingScreenData(
            id: 0,
            title: "Discovering Quests...",
            subtitle: "Adventures await around every corner",
            iconName: "map.fill",
            backgroundColor: .teal
        ),
        LoadingScreenData(
            id: 1,
            title: "Loading the World...",
            subtitle: "Millions of quests to explore",
            iconName: "globe.americas.fill",
            backgroundColor: .indigo
        ),
        LoadingScreenData(
            id: 2,
            title: "Preparing Your Adventure...",
            subtitle: "Get ready to explore the unknown",
            iconName: "figure.walk",
            backgroundColor: .orange
        ),
        LoadingScreenData(
            id: 3,
            title: "Connecting Explorers...",
            subtitle: "Join the global quest community",
            iconName: "person.3.fill",
            backgroundColor: .purple
        ),
        LoadingScreenData(
            id: 4,
            title: "Charting New Paths...",
            subtitle: "Your next discovery is just steps away",
            iconName: "location.north.fill",
            backgroundColor: .blue
        ),
    ]
}
