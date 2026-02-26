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
            if viewModel.isLoading && viewModel.messages.isEmpty {
                Spacer()
                GQLoadingIndicator(message: "Loading chat...")
                Spacer()
            } else if viewModel.messages.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 56, weight: .medium))
                        .foregroundStyle(GQTheme.primary.opacity(0.3))
                        .symbolEffect(.bounce, options: .repeating.speed(0.3))
                    Text("No messages yet")
                        .font(GQTheme.title3Font)
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
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, GQTheme.paddingMedium)
                        .padding(.vertical, GQTheme.paddingSmall)
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastId = viewModel.messages.last?.id {
                            withAnimation(GQTheme.bouncy) {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            Divider()

            inputBar(viewModel: viewModel)
        }
    }

    private func inputBar(viewModel: ChatViewModel) -> some View {
        @Bindable var vm = viewModel
        return HStack(spacing: 12) {
            TextField("Type a message...", text: $vm.messageText, axis: .vertical)
                .font(.system(.body, design: .rounded, weight: .medium))
                .lineLimit(1...4)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(GQTheme.cardBackground, in: RoundedRectangle(cornerRadius: GQTheme.cornerRadius))

            Button {
                Task {
                    guard let user = appState.currentUser else { return }
                    await viewModel.sendMessage(sender: user)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(viewModel.canSend ? GQTheme.primary : .gray.opacity(0.3))
                    .shadow(color: viewModel.canSend ? GQTheme.primary.opacity(0.3) : .clear, radius: 6)
            }
            .disabled(!viewModel.canSend)
            .buttonStyle(BouncyButtonStyle())
        }
        .padding(.horizontal, GQTheme.paddingMedium)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}
