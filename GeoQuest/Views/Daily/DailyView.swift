import SwiftUI

struct DailyView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: DailyViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    content(vm: vm)
                } else {
                    GQLoadingIndicator(message: "Loading daily challenges...")
                }
            }
            .navigationTitle("Daily")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { setupIfNeeded() }
        .task { await viewModel?.load() }
    }

    // MARK: - Main content

    private func content(vm: DailyViewModel) -> some View {
        ScrollView {
            VStack(spacing: GQTheme.paddingLarge) {
                streakBanner(vm: vm)
                loginBonusCard(vm: vm)
                objectivesSection(vm: vm)
                milestonesSection(vm: vm)
                resetCountdown()
                Spacer(minLength: GQTheme.paddingXLarge)
            }
            .padding(GQTheme.paddingLarge)
        }
        .refreshable { await vm.load() }
    }

    // MARK: - Streak banner

    private func streakBanner(vm: DailyViewModel) -> some View {
        GQCard(accentColor: streakColor(vm.currentStreak)) {
            HStack(spacing: GQTheme.paddingMedium) {
                // Flame with pulsing glow
                ZStack {
                    Circle()
                        .fill(streakColor(vm.currentStreak).opacity(0.18))
                        .frame(width: 70, height: 70)
                    Text("🔥")
                        .font(.system(size: 38))
                        .symbolEffect(.bounce, options: .nonRepeating)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(vm.currentStreak) Day Streak")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(streakColor(vm.currentStreak))

                    if vm.currentStreak == 0 {
                        Text("Log in every day to build your streak!")
                    } else if vm.currentStreak == 1 {
                        Text("Great start! Come back tomorrow.")
                    } else {
                        Text("Keep it going — \(vm.nextMilestone - vm.currentStreak) days to your next milestone!")
                    }
                }
                .font(GQTheme.captionFont)
                .foregroundStyle(.secondary)

                Spacer()

                VStack(spacing: 2) {
                    Text("\(vm.longestStreak)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(GQTheme.gold)
                    Text("Best")
                        .font(GQTheme.caption2Font)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Login bonus card

    private func loginBonusCard(vm: DailyViewModel) -> some View {
        GQCard {
            HStack(spacing: GQTheme.paddingMedium) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(GQTheme.accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Login Bonus")
                        .font(GQTheme.headlineFont)
                    HStack(spacing: 6) {
                        Label("\(vm.loginBonusGems) gems", systemImage: "diamond.fill")
                            .foregroundStyle(GQTheme.teal)
                        if vm.currentStreak > 0 && vm.currentStreak % AppConstants.Daily.streakMilestoneInterval == 0 {
                            Label("MILESTONE!", systemImage: "star.fill")
                                .foregroundStyle(GQTheme.gold)
                        }
                    }
                    .font(GQTheme.captionFont)
                }

                Spacer()

                if vm.loginBonusClaimed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(GQTheme.success)
                } else {
                    GQButtonSmall(title: "Claim", icon: "hand.tap.fill", color: GQTheme.accent) {
                        Task { await vm.claimLoginBonus() }
                    }
                }
            }
        }
    }

    // MARK: - Objectives section

    private func objectivesSection(vm: DailyViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Challenges")
                .font(GQTheme.headlineFont)

            if vm.isLoading {
                GQLoadingIndicator()
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(vm.objectives) { objective in
                    objectiveCard(objective: objective, vm: vm)
                }
            }
        }
    }

    @ViewBuilder
    private func objectiveCard(objective: DailyObjective, vm: DailyViewModel) -> some View {
        let isClaiming = vm.claimAnimation == objective.id
        let difficultyColor = self.difficultyColor(objective.template.difficulty)

        GQCard(accentColor: difficultyColor) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    // Difficulty pip
                    Capsule()
                        .fill(difficultyColor)
                        .frame(width: 6, height: 6)

                    Text(objective.template.title)
                        .font(GQTheme.headlineFont)

                    Spacer()

                    // State badge
                    if objective.isClaimed {
                        Label("Done", systemImage: "checkmark.seal.fill")
                            .font(GQTheme.caption2Font)
                            .foregroundStyle(GQTheme.success)
                    } else if objective.isComplete {
                        Label("Ready!", systemImage: "bell.fill")
                            .font(GQTheme.caption2Font)
                            .foregroundStyle(GQTheme.accent)
                    }
                }

                Text(objective.template.description)
                    .font(GQTheme.captionFont)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Progress bar
                let progress = min(Double(objective.progress) / Double(objective.template.targetCount), 1.0)
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.18))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(objective.isComplete ? GQTheme.success : difficultyColor)
                                .frame(width: geo.size.width * CGFloat(progress), height: 8)
                                .animation(GQTheme.smooth, value: progress)
                        }
                    }
                    .frame(height: 8)
                    Text("\(objective.progress) / \(objective.template.targetCount)")
                        .font(GQTheme.caption2Font)
                        .foregroundStyle(.secondary)
                }

                // Rewards row + claim button
                HStack {
                    // Reward chips
                    HStack(spacing: 8) {
                        rewardChip(icon: "star.fill", value: "+\(objective.template.rewardPoints)", color: GQTheme.primary)
                        rewardChip(icon: "diamond.fill", value: "+\(objective.template.rewardGems)", color: GQTheme.teal)
                    }

                    Spacer()

                    if !objective.isClaimed && objective.isComplete {
                        Button {
                            Task { await vm.claimObjective(at: objective.id) }
                        } label: {
                            Label("Claim", systemImage: isClaiming ? "checkmark" : "gift.fill")
                                .font(GQTheme.caption2Font.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(GQTheme.accent, in: Capsule())
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .scaleEffect(isClaiming ? 1.15 : 1.0)
                        .animation(GQTheme.bouncyHeavy, value: isClaiming)
                    }
                }
            }
        }
    }

    private func rewardChip(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(value)
                .font(GQTheme.caption2Font.bold())
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
    }

    // MARK: - Milestones section

    private func milestonesSection(vm: DailyViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streak Milestones")
                .font(GQTheme.headlineFont)

            let milestones = [7, 14, 30, 60, 100]
            GQCard {
                VStack(spacing: 0) {
                    ForEach(Array(milestones.enumerated()), id: \.offset) { idx, milestone in
                        let reached = vm.currentStreak >= milestone
                        HStack {
                            Image(systemName: reached ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(reached ? GQTheme.success : Color.secondary.opacity(0.4))

                            Text("\(milestone) day streak")
                                .font(GQTheme.bodyFont)
                                .foregroundStyle(reached ? .primary : .secondary)

                            Spacer()

                            Label("+\(AppConstants.Daily.streakMilestoneGems) gems", systemImage: "diamond.fill")
                                .font(GQTheme.captionFont)
                                .foregroundStyle(reached ? GQTheme.teal : Color.secondary.opacity(0.5))
                        }
                        .padding(.vertical, 8)

                        if idx < milestones.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Reset countdown

    private func resetCountdown() -> some View {
        let nextMidnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
        let remaining = nextMidnight.timeIntervalSinceNow
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        return HStack {
            Image(systemName: "clock")
            Text("Resets in \(hours)h \(minutes)m")
        }
        .font(GQTheme.captionFont)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func setupIfNeeded() {
        guard viewModel == nil, let user = appState.currentUser else { return }
        viewModel = DailyViewModel(
            dailyService: appState.dailyObjectiveService,
            userId: user.id,
            currentStreak: user.currentStreak,
            longestStreak: user.longestStreak
        )
    }

    private func difficultyColor(_ difficulty: DailyObjectiveTemplate.ObjectiveDifficulty) -> Color {
        switch difficulty {
        case .easy:   return GQTheme.success
        case .medium: return GQTheme.primary
        case .hard:   return GQTheme.error
        }
    }

    private func streakColor(_ streak: Int) -> Color {
        switch streak {
        case 0:       return .secondary
        case 1...6:   return GQTheme.accent
        case 7...13:  return GQTheme.primary
        case 14...29: return GQTheme.secondary
        case 30...:   return GQTheme.gold
        default:      return GQTheme.accent
        }
    }
}
