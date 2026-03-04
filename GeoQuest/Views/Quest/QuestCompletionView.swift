import SwiftUI

struct QuestCompletionView: View {
    @Bindable var viewModel: QuestDetailViewModel
    let quest: Quest
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var showConfetti = false
    @State private var showUnlockOverlay = false

    var body: some View {
        ZStack {
        ScrollView {
            VStack(spacing: GQTheme.paddingLarge) {
                Spacer(minLength: 20)

                // Celebration icon
                ZStack {
                    Circle()
                        .fill(GQTheme.success.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(showConfetti ? 1.0 : 0.5)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.yellow)
                        .symbolEffect(.bounce, options: .nonRepeating)
                }

                Text("Quest Complete!")
                    .font(GQTheme.titleFont)
                    .foregroundStyle(GQTheme.success)

                Text(quest.title)
                    .font(GQTheme.headlineFont)
                    .foregroundStyle(.secondary)

                // Points earned
                GQCard {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("+\(viewModel.pointsEarned)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(GQTheme.accent)
                            Text("Points Earned")
                                .font(GQTheme.captionFont)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                // Rating section
                if viewModel.showRating {
                    VStack(spacing: 16) {
                        Text("Rate this Quest")
                            .font(GQTheme.headlineFont)

                        StarRatingView(rating: $viewModel.ratingValue, size: 36)

                        GQTextField(
                            placeholder: "Leave feedback (optional)",
                            text: $viewModel.feedbackText,
                            icon: "text.bubble.fill",
                            maxLength: 500
                        )

                        GQButton(
                            title: "Submit Rating",
                            icon: "star.fill",
                            color: .yellow,
                            isDisabled: viewModel.ratingValue == 0
                        ) {
                            Task {
                                guard let user = appState.currentUser else { return }
                                await viewModel.submitRating(userId: user.id, userDisplayName: user.displayName)
                            }
                        }
                    }
                    .padding(.top, GQTheme.paddingMedium)
                }

                // Return button
                GQGameButton(title: "Return to Map", icon: "map.fill", color: GQTheme.primary) {
                    dismiss()
                }
                .padding(.top, GQTheme.paddingMedium)
            }
            .padding(GQTheme.paddingLarge)
        }
        .onAppear {
            withAnimation(GQTheme.bouncy) {
                showConfetti = true
            }
            if viewModel.unlockedCosmetic != nil {
                // Delay to let completion celebration play first
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showUnlockOverlay = true
                }
            }
        }

        // Cosmetic unlock overlay
        if showUnlockOverlay, let cosmetic = viewModel.unlockedCosmetic {
            CosmeticUnlockView(item: cosmetic) {
                withAnimation(GQTheme.bouncy) {
                    showUnlockOverlay = false
                }
            }
            .transition(.opacity)
        }
        } // ZStack
    }
}
