import SwiftUI

struct FriendsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: FriendViewModel?
    @State private var selectedTab: FriendsTab = .friends
    @State private var appeared = false

    enum FriendsTab: String, CaseIterable {
        case friends = "Friends"
        case requests = "Requests"
        case search = "Search"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom segmented control
                friendsTabPicker

                // Content
                Group {
                    switch selectedTab {
                    case .friends:
                        friendsListSection
                    case .requests:
                        requestsSection
                    case .search:
                        searchSection
                    }
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .gqDismissToolbar(dismiss: dismiss)
        }
        .gqMenuSheet()
        .onAppear {
            if viewModel == nil {
                viewModel = FriendViewModel(
                    friendService: appState.friendService,
                    userService: appState.userService
                )
            }
            if let userId = appState.currentUser?.id {
                Task { await viewModel?.loadAll(userId: userId) }
            }
            withAnimation(GQTheme.bouncy) { appeared = true }
        }
        .overlay(alignment: .top) {
            if let msg = viewModel?.successMessage {
                toastBanner(msg, color: GQTheme.success)
            }
            if let msg = viewModel?.errorMessage {
                toastBanner(msg, color: GQTheme.error)
            }
        }
    }

    // MARK: - Tab Picker

    private var friendsTabPicker: some View {
        HStack(spacing: 4) {
            ForEach(FriendsTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(GQTheme.bouncyQuick) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                        if tab == .requests, let vm = viewModel, !vm.incomingRequests.isEmpty {
                            Text("\(vm.incomingRequests.count)")
                                .font(.system(.caption2, design: .rounded, weight: .heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(GQTheme.error, in: Capsule())
                        }
                    }
                    .foregroundStyle(selectedTab == tab ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        selectedTab == tab
                            ? AnyShapeStyle(GQTheme.primary)
                            : AnyShapeStyle(GQTheme.cardBackground),
                        in: Capsule()
                    )
                }
                .buttonStyle(BouncyButtonStyle())
            }
        }
        .padding(.horizontal, GQTheme.paddingMedium)
        .padding(.vertical, GQTheme.paddingSmall)
    }

    // MARK: - Friends List

    private var friendsListSection: some View {
        Group {
            if let viewModel, viewModel.isLoading {
                Spacer()
                GQLoadingIndicator(message: "Loading friends...")
                Spacer()
            } else if let viewModel, viewModel.friends.isEmpty {
                Spacer()
                emptyState(
                    icon: "person.2.fill",
                    title: "No friends yet",
                    subtitle: "Search for players and send them a request!",
                    color: GQTheme.pink
                )
                Spacer()
            } else if let viewModel {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(viewModel.friends.enumerated()), id: \.element.id) { index, friend in
                            friendRow(friend: friend)
                                .scaleEffect(appeared ? 1 : 0.8)
                                .opacity(appeared ? 1 : 0)
                                .animation(GQTheme.bouncy.delay(Double(index) * 0.04), value: appeared)
                        }
                    }
                    .padding(GQTheme.paddingMedium)
                }
            }
        }
    }

    private func friendRow(friend: Friendship) -> some View {
        HStack(spacing: 14) {
            AvatarPreviewView(config: friend.friendAvatarConfig, size: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(friend.friendDisplayName)
                    .font(GQTheme.headlineFont)
                Text("Friends since \(friend.createdAt.shortFormatted)")
                    .font(GQTheme.caption2Font)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(GQTheme.paddingMedium)
        .background(
            RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                .fill(GQTheme.cardBackground)
        )
        .gqShadow()
    }

    // MARK: - Requests

    private var requestsSection: some View {
        Group {
            if let viewModel, viewModel.incomingRequests.isEmpty {
                Spacer()
                emptyState(
                    icon: "envelope.fill",
                    title: "No pending requests",
                    subtitle: "Friend requests will show up here",
                    color: GQTheme.secondary
                )
                Spacer()
            } else if let viewModel {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.incomingRequests) { request in
                            requestCard(request: request)
                        }
                    }
                    .padding(GQTheme.paddingMedium)
                }
            }
        }
    }

    private func requestCard(request: FriendRequest) -> some View {
        HStack(spacing: 14) {
            AvatarPreviewView(config: request.fromAvatarConfig, size: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(request.fromDisplayName)
                    .font(GQTheme.headlineFont)
                Text("Wants to be friends!")
                    .font(GQTheme.caption2Font)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    Task { await viewModel?.acceptRequest(request) }
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(GQTheme.success)
                }
                .buttonStyle(BouncyButtonStyle())

                Button {
                    Task { await viewModel?.rejectRequest(request) }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(GQTheme.error)
                }
                .buttonStyle(BouncyButtonStyle())
            }
        }
        .padding(GQTheme.paddingMedium)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                    .fill(GQTheme.cardBackground)
                RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                    .stroke(GQTheme.success.opacity(0.2), lineWidth: 2)
            }
        )
        .gqShadow()
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Search

    private var searchSection: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 12) {
                GQTextField(
                    placeholder: "Search by username...",
                    text: Binding(
                        get: { viewModel?.searchQuery ?? "" },
                        set: { viewModel?.searchQuery = $0 }
                    ),
                    icon: "magnifyingglass"
                )

                if viewModel?.isSearching == true {
                    ProgressView()
                } else {
                    Button {
                        guard let userId = appState.currentUser?.id else { return }
                        Task { await viewModel?.searchUsers(currentUserId: userId) }
                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(GQTheme.primary)
                    }
                    .buttonStyle(BouncyButtonStyle())
                }
            }
            .padding(GQTheme.paddingMedium)

            if let viewModel {
                if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty && !viewModel.isSearching {
                    Spacer()
                    emptyState(
                        icon: "magnifyingglass",
                        title: "No players found",
                        subtitle: "Try a different username",
                        color: GQTheme.primary
                    )
                    Spacer()
                } else if viewModel.searchResults.isEmpty {
                    Spacer()
                    emptyState(
                        icon: "person.badge.plus",
                        title: "Find friends",
                        subtitle: "Search for players by username",
                        color: GQTheme.primary
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.searchResults) { user in
                                searchResultRow(user: user)
                            }
                        }
                        .padding(.horizontal, GQTheme.paddingMedium)
                    }
                }
            }
        }
    }

    private func searchResultRow(user: GQUser) -> some View {
        HStack(spacing: 14) {
            AvatarPreviewView(config: user.avatarConfig, size: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(user.displayName)
                    .font(GQTheme.headlineFont)
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(GQTheme.gold)
                    Text("\(user.totalScore) pts")
                        .foregroundStyle(.secondary)
                }
                .font(GQTheme.caption2Font)
            }

            Spacer()

            if viewModel?.hasPendingRequest(toUserId: user.id) == true {
                Text("Pending")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(GQTheme.warning)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(GQTheme.warning.opacity(0.15), in: Capsule())
            } else {
                Button {
                    guard let currentUser = appState.currentUser else { return }
                    Task { await viewModel?.sendRequest(from: currentUser, to: user) }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(GQTheme.primary, in: Capsule())
                }
                .buttonStyle(BouncyButtonStyle())
            }
        }
        .padding(GQTheme.paddingMedium)
        .background(
            RoundedRectangle(cornerRadius: GQTheme.cornerRadius)
                .fill(GQTheme.cardBackground)
        )
        .gqShadow()
    }

    // MARK: - Helpers

    private func emptyState(icon: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 52, weight: .medium))
                .foregroundStyle(color.opacity(0.4))
                .symbolEffect(.bounce, options: .repeating.speed(0.3))
            Text(title)
                .font(GQTheme.title3Font)
                .foregroundStyle(.secondary)
            Text(subtitle)
                .font(GQTheme.captionFont)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func toastBanner(_ message: String, color: Color) -> some View {
        Text(message)
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(color, in: Capsule())
            .shadow(color: color.opacity(0.3), radius: 8, y: 4)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(GQTheme.smooth) {
                        viewModel?.clearMessages()
                    }
                }
            }
    }
}
