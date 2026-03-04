import SwiftUI
struct QuestPlayView: View {
    @Bindable var viewModel: QuestDetailViewModel
    let quest: Quest
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            progressBar

            ScrollView {
                VStack(spacing: GQTheme.paddingLarge) {
                    if case .playing(let currentStep) = viewModel.playState {
                        stepView(step: quest.steps[currentStep], index: currentStep)
                    } else if case .enteringCode = viewModel.playState {
                        codeEntryView
                    }
                }
                .padding(GQTheme.paddingLarge)
            }
        }
        .navigationTitle(quest.title)
    }

    // MARK: - Progress

    private var progressBar: some View {
        let totalSteps = quest.steps.count + 1 // +1 for code entry
        let currentIndex: Int = {
            switch viewModel.playState {
            case .playing(let step): return step
            case .enteringCode: return quest.steps.count
            default: return 0
            }
        }()

        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)

                Rectangle()
                    .fill(GQTheme.accent)
                    .frame(width: geometry.size.width * CGFloat(currentIndex + 1) / CGFloat(totalSteps), height: 4)
                    .animation(GQTheme.smooth, value: currentIndex)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Step View

    private func stepView(step: QuestStep, index: Int) -> some View {
        VStack(spacing: GQTheme.paddingLarge) {
            // Step number
            Text("Step \(index + 1) of \(quest.steps.count)")
                .font(GQTheme.captionFont)
                .foregroundStyle(.secondary)

            // Step instruction
            GQCard {
                VStack(spacing: 12) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 36))
                        .foregroundStyle(GQTheme.accent)

                    Text(step.instruction)
                        .font(GQTheme.bodyFont)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, GQTheme.paddingMedium)
            }

            // Navigation buttons
            HStack(spacing: 16) {
                if index > 0 {
                    Button {
                        viewModel.previousStep()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(GQTheme.headlineFont)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: GQTheme.buttonHeight)
                        .background(GQTheme.cardBackground, in: RoundedRectangle(cornerRadius: GQTheme.cornerRadius))
                    }
                    .buttonStyle(BouncyButtonStyle())
                }

                GQGameButton(
                    title: index < quest.steps.count - 1 ? "Next Step" : "Enter Code",
                    icon: index < quest.steps.count - 1 ? "chevron.right" : "key.fill",
                    color: GQTheme.accent
                ) {
                    viewModel.nextStep()
                }
            }
        }
    }

    // MARK: - Code Entry

    private var codeEntryView: some View {
        VStack(spacing: GQTheme.paddingLarge) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 48))
                .foregroundStyle(GQTheme.accent)

            Text("Enter the Secret Code")
                .font(GQTheme.title3Font)

            Text("Find the code on the quest object and enter it below")
                .font(GQTheme.bodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            GQTextField(
                placeholder: "Secret Code",
                text: $viewModel.enteredCode,
                icon: "key.fill",
                maxLength: AppConstants.maxSecretCodeLength
            )
            .textInputAutocapitalization(.characters)

            if let error = viewModel.codeError {
                Text(error)
                    .font(GQTheme.captionFont)
                    .foregroundStyle(GQTheme.error)
            }

            GQGameButton(
                title: viewModel.isWithinProximity ? "Submit Code" : "Too Far Away",
                icon: viewModel.isWithinProximity ? "checkmark.circle.fill" : "location.slash.fill",
                color: viewModel.isWithinProximity ? GQTheme.success : .gray,
                isDisabled: viewModel.enteredCode.isEmpty || !viewModel.isWithinProximity
            ) {
                Task {
                    guard let user = appState.currentUser else { return }
                    _ = await viewModel.submitCode(userId: user.id, userDisplayName: user.displayName)
                }
            }

            if !viewModel.isWithinProximity {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(GQTheme.warning)
                    Text("Move closer to the quest to submit")
                        .font(GQTheme.captionFont)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                viewModel.previousStep()
                viewModel.playState = .playing(currentStep: quest.steps.count - 1)
            } label: {
                Text("Back to Steps")
                    .font(GQTheme.bodyFont)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
