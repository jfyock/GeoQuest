import SwiftUI

@Observable
final class ChatViewModel {
    var messageText = ""
    var isSending = false

    private let chatService: ChatService

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    var messages: [ChatMessage] {
        chatService.messages
    }

    var isLoading: Bool {
        chatService.isLoading
    }

    func startListening() {
        chatService.startListening()
    }

    func stopListening() {
        chatService.stopListening()
    }

    func sendMessage(sender: GQUser) async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isSending = true
        defer { isSending = false }

        do {
            try await chatService.sendMessage(text: text, sender: sender)
            messageText = ""
        } catch {
            // Send failed
        }
    }

    var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }
}
