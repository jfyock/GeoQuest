import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage
    let isOwnMessage: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if isOwnMessage { Spacer(minLength: 60) }

            if !isOwnMessage {
                AvatarPreviewView(config: message.senderAvatarConfig, size: 32)
            }

            VStack(alignment: isOwnMessage ? .trailing : .leading, spacing: 4) {
                if !isOwnMessage {
                    Text(message.senderDisplayName)
                        .font(GQTheme.caption2Font.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text(message.text)
                    .font(GQTheme.bodyFont)
                    .foregroundStyle(isOwnMessage ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isOwnMessage ? GQTheme.primary : GQTheme.cardBackground,
                        in: ChatBubbleShape(isOwnMessage: isOwnMessage)
                    )

                Text(message.sentAt.chatTimestamp)
                    .font(GQTheme.caption2Font)
                    .foregroundStyle(.tertiary)
            }

            if !isOwnMessage { Spacer(minLength: 60) }
        }
    }
}

struct ChatBubbleShape: Shape {
    let isOwnMessage: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        let smallRadius: CGFloat = 4

        var path = Path()

        if isOwnMessage {
            // Top-left rounded, top-right rounded, bottom-left rounded, bottom-right sharp
            path.addRoundedRect(
                in: rect,
                cornerRadii: RectangleCornerRadii(
                    topLeading: radius,
                    bottomLeading: radius,
                    bottomTrailing: smallRadius,
                    topTrailing: radius
                )
            )
        } else {
            // Top-left sharp, top-right rounded, bottom-left rounded, bottom-right rounded
            path.addRoundedRect(
                in: rect,
                cornerRadii: RectangleCornerRadii(
                    topLeading: radius,
                    bottomLeading: smallRadius,
                    bottomTrailing: radius,
                    topTrailing: radius
                )
            )
        }

        return path
    }
}
