import SwiftUI

struct QuestCreationView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: QuestCreationViewModel?
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    creationForm(viewModel: viewModel)
                } else {
                    GQLoadingIndicator()
                }
            }
            .navigationTitle("Create Quest")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = QuestCreationViewModel(
                    questService: appState.questService,
                    userService: appState.userService,
                    leaderboardService: appState.leaderboardService
                )
            }
        }
    }

    private func creationForm(viewModel: QuestCreationViewModel) -> some View {
        ScrollView {
            VStack(spacing: GQTheme.paddingLarge) {
                // Success state
                if case .success = viewModel.state {
                    successView(viewModel: viewModel)
                } else {
                    formContent(viewModel: viewModel)
                }
            }
            .padding(GQTheme.paddingLarge)
        }
    }

    // MARK: - Form Content

    @ViewBuilder
    private func formContent(viewModel: QuestCreationViewModel) -> some View {
        // Title
        VStack(alignment: .leading, spacing: 8) {
            Text("Quest Title")
                .font(GQTheme.headlineFont)
            GQTextField(
                placeholder: "Name your quest...",
                text: Binding(get: { viewModel.title }, set: { viewModel.title = $0 }),
                icon: "pencil",
                maxLength: AppConstants.maxQuestTitleCharacters
            )
        }

        // Description
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(GQTheme.headlineFont)
            GQTextField(
                placeholder: "Describe what players will find...",
                text: Binding(get: { viewModel.description }, set: { viewModel.description = $0 }),
                icon: "text.alignleft",
                maxLength: AppConstants.maxQuestDescriptionCharacters
            )
        }

        // Difficulty
        VStack(alignment: .leading, spacing: 8) {
            Text("Difficulty")
                .font(GQTheme.headlineFont)
            HStack(spacing: 10) {
                ForEach(QuestDifficulty.allCases, id: \.self) { level in
                    Button {
                        withAnimation(GQTheme.bouncyQuick) {
                            viewModel.difficulty = level
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: level.iconName)
                                .font(.system(size: 18))
                            Text(level.displayName)
                                .font(GQTheme.caption2Font)
                        }
                        .foregroundStyle(viewModel.difficulty == level ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            viewModel.difficulty == level
                                ? difficultyColor(level)
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: GQTheme.cornerRadiusSmall)
                        )
                        .overlay {
                            if viewModel.difficulty != level {
                                RoundedRectangle(cornerRadius: GQTheme.cornerRadiusSmall)
                                    .strokeBorder(.secondary.opacity(0.3), lineWidth: 1)
                            }
                        }
                    }
                    .buttonStyle(BouncyScaleStyle())
                }
            }
        }

        // Location
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(GQTheme.headlineFont)

            HStack(spacing: 12) {
                Image(systemName: viewModel.useCurrentLocation ? "location.fill" : "mappin")
                    .foregroundStyle(GQTheme.primary)
                VStack(alignment: .leading) {
                    Text(viewModel.useCurrentLocation ? "Using Current Location" : "Custom Location")
                        .font(GQTheme.bodyFont)
                    if let loc = appState.locationService.currentLocation, viewModel.useCurrentLocation {
                        Text(String(format: "%.4f, %.4f", loc.latitude, loc.longitude))
                            .font(GQTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .gqCard()
        }

        // Steps
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quest Steps")
                    .font(GQTheme.headlineFont)
                Spacer()
                Text("\(viewModel.steps.count)/\(AppConstants.maxQuestSteps)")
                    .font(GQTheme.captionFont)
                    .foregroundStyle(.secondary)
            }

            ForEach(viewModel.steps.indices, id: \.self) { index in
                QuestStepEditorView(
                    stepNumber: index + 1,
                    instruction: Binding(
                        get: { viewModel.steps[index].instruction },
                        set: { viewModel.steps[index].instruction = $0 }
                    ),
                    canDelete: viewModel.steps.count > AppConstants.minQuestSteps,
                    onDelete: { viewModel.removeStep(at: index) }
                )
            }

            if viewModel.steps.count < AppConstants.maxQuestSteps {
                Button {
                    viewModel.addStep()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Step")
                    }
                    .font(GQTheme.headlineFont)
                    .foregroundStyle(GQTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(GQTheme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: GQTheme.cornerRadiusSmall))
                }
                .buttonStyle(BouncyButtonStyle())
            }
        }

        // Secret Code
        VStack(alignment: .leading, spacing: 8) {
            Text("Secret Code")
                .font(GQTheme.headlineFont)
            Text("This code should be written on the quest object for finders to discover.")
                .font(GQTheme.captionFont)
                .foregroundStyle(.secondary)
            GQTextField(
                placeholder: "Enter 4-20 character code",
                text: Binding(get: { viewModel.secretCode }, set: { viewModel.secretCode = $0 }),
                icon: "key.fill",
                maxLength: AppConstants.maxSecretCodeLength
            )
            .textInputAutocapitalization(.characters)
        }

        // Icon & Color
        VStack(alignment: .leading, spacing: 12) {
            Text("Quest Icon")
                .font(GQTheme.headlineFont)
            IconPickerView(
                selectedIcon: Binding(get: { viewModel.selectedIcon }, set: { viewModel.selectedIcon = $0 }),
                iconColor: Color(hex: viewModel.selectedColor)
            )
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("Quest Color")
                .font(GQTheme.headlineFont)
            ColorPickerGridView(
                selectedColorHex: Binding(get: { viewModel.selectedColor }, set: { viewModel.selectedColor = $0 })
            )
        }

        // Points preview
        GQCard {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("Players earn \(viewModel.estimatedPoints) base points")
                    .font(GQTheme.bodyFont)
                Spacer()
            }
        }

        // Error
        if case .error(let message) = viewModel.state {
            Text(message)
                .font(GQTheme.captionFont)
                .foregroundStyle(GQTheme.error)
                .multilineTextAlignment(.center)
        }

        // Submit button
        GQButton(
            title: "Create Quest",
            icon: "plus.circle.fill",
            color: GQTheme.accent,
            isLoading: {
                if case .submitting = viewModel.state { return true }
                return false
            }(),
            isDisabled: !viewModel.isValid
        ) {
            Task {
                guard let user = appState.currentUser else { return }
                await viewModel.createQuest(
                    userId: user.id,
                    displayName: user.displayName,
                    currentLocation: appState.locationService.currentLocation
                )
            }
        }
    }

    // MARK: - Success View

    private func successView(viewModel: QuestCreationViewModel) -> some View {
        VStack(spacing: GQTheme.paddingLarge) {
            Spacer(minLength: 60)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(GQTheme.success)
                .symbolEffect(.bounce, options: .nonRepeating)

            Text("Quest Created!")
                .font(GQTheme.titleFont)

            Text("Your quest is now live. Other players can find and complete it!")
                .font(GQTheme.bodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            GQCard {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("+\(ScoreCalculator.questCreationPoints)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(GQTheme.accent)
                        Text("Creation Points")
                            .font(GQTheme.captionFont)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }

            GQButton(title: "Create Another", icon: "plus.circle", color: GQTheme.primary) {
                withAnimation(GQTheme.smooth) {
                    viewModel.reset()
                }
            }

            Spacer()
        }
    }

    private func difficultyColor(_ difficulty: QuestDifficulty) -> Color {
        switch difficulty {
        case .easy: return GQTheme.easyColor
        case .medium: return GQTheme.mediumColor
        case .hard: return GQTheme.hardColor
        case .expert: return GQTheme.expertColor
        }
    }
}
