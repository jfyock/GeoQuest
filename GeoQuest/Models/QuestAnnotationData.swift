import SwiftUI
import CoreLocation

struct QuestAnnotationData: Identifiable, Sendable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let title: String
    let iconName: String
    let iconColor: Color
    let difficulty: QuestDifficulty
    let completionCount: Int
    let rating: Double
    let isCompletedByCurrentUser: Bool

    init(from quest: Quest, isCompleted: Bool = false) {
        self.id = quest.id
        self.coordinate = CLLocationCoordinate2D(latitude: quest.latitude, longitude: quest.longitude)
        self.title = quest.title
        self.iconName = quest.iconName
        self.iconColor = Color(hex: quest.iconColor)
        self.difficulty = quest.difficulty
        self.completionCount = quest.totalCompletions
        self.rating = quest.averageRating
        self.isCompletedByCurrentUser = isCompleted
    }
}
