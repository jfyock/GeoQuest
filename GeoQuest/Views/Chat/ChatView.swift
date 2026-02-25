import SwiftUI

struct ChatView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: ChatViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    chatContent(viewModel: viewModel)
                } else {
                    GQLoadingIndicator()
                }
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ChatViewModel(chatService: appState.chatService)
                viewModel?.startListening()
            }
        }
        .onDisappear {
            viewModel?.stopListening()
        }
    }

    private func chatContent(viewModel: ChatViewModel) -> some View {
        VStack(spacing: 0) {
            // Messages
            if viewModel.isLoading && viewModel.messages.isEmpty {
                Spacer()
                GQLoadingIndicator(message: "Loading chat...")
                Spacer()
            } else if viewModel.messages.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("No messages yet")
                        .font(GQTheme.bodyFont)
                        .foregroundStyle(.secondary)
                    Text("Be the first to say hello!")
                        .font(GQTheme.captionFont)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.messages) { message in
                                ChatBubbleView(
                                    message: message,
                                    isOwnMessage: message.senderId == appState.currentUser?.id
                                )
                                .id(message.id)
                            }
                        }
                        .padding(.horizontal, GQTheme.paddingMedium)
                        .padding(.vertical, GQTheme.paddingSmall)
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastId = viewModel.messages.last?.id {
                            withAnimation(GQTheme.smooth) {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            Divider()

            // Input bar
            inputBar(viewModel: viewModel)
        }
    }

    private func inputBar(viewModel: ChatViewModel) -> some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: Binding(
                get: { viewModel.messageText },
                set: { viewModel.messageText = $0 }
            ), axis: .vertical)
                .font(GQTheme.bodyFont)
                .lineLimit(1...4)
                .padding(12)
                .background(GQTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20))

            Button {
                Task {
                    guard let user = appState.currentUser else { return }
                    await viewModel.sendMessage(sender: user)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(viewModel.canSend ? GQTheme.primary : .gray.opacity(0.4))
            }
            .disabled(!viewModel.canSend)
            .buttonStyle(BouncyButtonStyle())
        }
        .padding(.horizontal, GQTheme.paddingMedium)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
