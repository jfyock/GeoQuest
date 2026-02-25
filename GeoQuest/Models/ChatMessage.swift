import Foundation

struct ChatMessage: Codable, Identifiable, Sendable {
    var id: String
    var senderId: String
    var senderDisplayName: String
    var senderAvatarConfig: AvatarConfig
    var text: String
    var sentAt: Date

    init(
        id: String = "",
        senderId: String,
        senderDisplayName: String,
        senderAvatarConfig: AvatarConfig,
        text: String
    ) {
        self.id = id
        self.senderId = senderId
        self.senderDisplayName = senderDisplayName
        self.senderAvatarConfig = senderAvatarConfig
        self.text = text.truncated(to: AppConstants.maxChatMessageLength)
        self.sentAt = Date()
    }
}
