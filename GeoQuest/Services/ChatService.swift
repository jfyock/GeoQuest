import FirebaseFirestore

@Observable
final class ChatService {
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private(set) var messages: [ChatMessage] = []
    private(set) var isLoading = false

    func startListening(limit: Int = AppConstants.chatMessageFetchLimit) {
        isLoading = true
        listener = db.collection(AppConstants.Collections.chatMessages)
            .order(by: "sentAt", descending: false)
            .limit(toLast: limit)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, let snapshot else { return }
                self.messages = snapshot.documents.compactMap { doc in
                    guard var message = try? doc.data(as: ChatMessage.self) else { return nil }
                    message.id = doc.documentID
                    return message
                }
                self.isLoading = false
            }
    }

    func sendMessage(text: String, sender: GQUser) async throws {
        let message = ChatMessage(
            senderId: sender.id,
            senderDisplayName: sender.displayName,
            senderAvatarConfig: sender.avatarConfig,
            text: text
        )
        try db.collection(AppConstants.Collections.chatMessages).addDocument(from: message)
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    deinit {
        stopListening()
    }
}
