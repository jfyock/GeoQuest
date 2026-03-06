import SwiftUI

/// A popup that appears once per day when the user first opens the app,
/// showing their current streak and today's daily objectives as a reminder.
struct DailyStreakPopupView: View {
    let currentStreak: Int
    let longestStreak: Int
    let objectives: [DailyObjectiveTemplate]
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(appeared ? 0.45 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                // Streak header
                VStack(spacing: 8) {
                    Text("🔥")
                        .font(.system(size: 56))

                    Text(currentStreak == 0 ? "Welcome Back!" : "\(currentStreak) Day Streak!")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(streakColor)

                    if currentStreak > 1 {
                        Text("Best: \(longestStreak) days")
                            .font(GQTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }

                    if currentStreak == 0 {
                        Text("Complete today's challenges to start a streak!")
                            .font(GQTheme.captionFont)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        let interval = AppConstants.Daily.streakMilestoneInterval
                        let daysToMilestone = interval - (currentStreak % interval)
                        if daysToMilestone == interval {
                            Text("Milestone reached! Claim your bonus gems!")
                                .font(GQTheme.captionFont)
                                .foregroundStyle(GQTheme.gold)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("\(daysToMilestone) days to your next milestone reward")
                                .font(GQTheme.captionFont)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(.top, 28)
                .padding(.horizontal, 24)

                // Divider
                Divider()
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)

                // Today's objectives preview
                VStack(alignment: .leading, spacing: 10) {
                    Text("Today's Challenges")
                        .font(GQTheme.headlineFont)
                        .padding(.horizontal, 24)

                    ForEach(objectives, id: \.index) { objective in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(difficultyColor(objective.difficulty))
                                .frame(width: 8, height: 8)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(objective.title)
                                    .font(GQTheme.bodyFont)
                                Text(objective.description)
                                    .font(GQTheme.caption2Font)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            HStack(spacing: 4) {
                                Image(systemName: "diamond.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(GQTheme.teal)
                                Text("+\(objective.rewardGems)")
                                    .font(GQTheme.caption2Font.bold())
                                    .foregroundStyle(GQTheme.teal)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }

                // Login bonus reminder
                HStack(spacing: 10) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(GQTheme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Login Bonus")
                            .font(GQTheme.captionFont.bold())
                        Text("+\(AppConstants.Daily.loginGems) gems waiting for you!")
                            .font(GQTheme.caption2Font)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(GQTheme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: GQTheme.cornerRadiusSmall))
                .padding(.horizontal, 24)
                .padding(.top, 12)

                // Dismiss button
                Button {
                    dismiss()
                } label: {
                    Text("Let's Go!")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(GQTheme.accentGradient, in: RoundedRectangle(cornerRadius: GQTheme.cornerRadiusSmall))
                }
                .buttonStyle(BouncyButtonStyle())
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: GQTheme.cornerRadiusLarge))
            .padding(.horizontal, 28)
            .scaleEffect(appeared ? 1.0 : 0.7)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(GQTheme.bouncy) {
                appeared = true
            }
        }
    }

    private func dismiss() {
        withAnimation(GQTheme.smooth) {
            appeared = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }

    private var streakColor: Color {
        switch currentStreak {
        case 0:       return .secondary
        case 1...6:   return GQTheme.accent
        case 7...13:  return GQTheme.primary
        case 14...29: return GQTheme.secondary
        case 30...:   return GQTheme.gold
        default:      return GQTheme.accent
        }
    }

    private func difficultyColor(_ difficulty: DailyObjectiveTemplate.ObjectiveDifficulty) -> Color {
        switch difficulty {
        case .easy:   return GQTheme.success
        case .medium: return GQTheme.primary
        case .hard:   return GQTheme.error
        }
    }
}
