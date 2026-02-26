import SwiftUI

struct ChatBubbleView: View {
    let message: ChatMessage
    let isOwnMessage: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if isOwnMessage { Spacer(minLength: 60) }

            if !isOwnMessage {
                AvatarPreviewView(config: message.senderAvatarConfig, size: 34)
            }

            VStack(alignment: isOwnMessage ? .trailing : .leading, spacing: 4) {
                if !isOwnMessage {
                    Text(message.senderDisplayName)
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(.secondary)
                }

                Text(message.text)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(isOwnMessage ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(
                        ZStack {
                            ChatBubbleShape(isOwnMessage: isOwnMessage)
                                .fill(isOwnMessage ? GQTheme.primary : GQTheme.cardBackground)
                            if isOwnMessage {
                                ChatBubbleShape(isOwnMessage: isOwnMessage)
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.15), .clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                        }
                    )
                    .shadow(
                        color: isOwnMessage ? GQTheme.primary.opacity(0.2) : .black.opacity(0.06),
                        radius: 4, x: 0, y: 2
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
        let radius: CGFloat = 18
        let smallRadius: CGFloat = 4

        var path = Path()

        if isOwnMessage {
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
