import SwiftUI

struct AvatarCustomizationView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: AvatarViewModel?

    var body: some View {
        Group {
            if let viewModel {
                customizationContent(viewModel: viewModel)
            } else {
                GQLoadingIndicator()
            }
        }
        .navigationTitle("Customize Avatar")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = AvatarViewModel(
                    config: appState.currentUser?.avatarConfig ?? .default,
                    userService: appState.userService,
                    leaderboardService: appState.leaderboardService
                )
            }
        }
    }

    private func customizationContent(viewModel: AvatarViewModel) -> some View {
        ScrollView {
            VStack(spacing: GQTheme.paddingLarge) {
                // Live preview
                AvatarPreviewView(config: viewModel.config, size: 120)
                    .animation(GQTheme.bouncy, value: viewModel.config)
                    .padding(.top, GQTheme.paddingMedium)

                // Body Color
                sectionView(title: "Body Color", icon: "paintpalette.fill") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                        ForEach(AvatarBodyColor.allCases, id: \.self) { color in
                            colorCircle(
                                color: bodySwiftUIColor(color),
                                isSelected: viewModel.config.bodyColor == color
                            ) {
                                withAnimation(GQTheme.bouncyQuick) {
                                    viewModel.config.bodyColor = color
                                }
                            }
                        }
                    }
                }

                // Eye Style
                sectionView(title: "Eyes", icon: "eye.fill") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                        ForEach(AvatarEyeStyle.allCases, id: \.self) { style in
                            optionButton(
                                label: style.rawValue.capitalized,
                                isSelected: viewModel.config.eyeStyle == style
                            ) {
                                withAnimation(GQTheme.bouncyQuick) {
                                    viewModel.config.eyeStyle = style
                                }
                            }
                        }
                    }
                }

                // Mouth Style
                sectionView(title: "Mouth", icon: "mouth.fill") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                        ForEach(AvatarMouthStyle.allCases, id: \.self) { style in
                            optionButton(
                                label: style.rawValue.capitalized,
                                isSelected: viewModel.config.mouthStyle == style
                            ) {
                                withAnimation(GQTheme.bouncyQuick) {
                                    viewModel.config.mouthStyle = style
                                }
                            }
                        }
                    }
                }

                // Accessory
                sectionView(title: "Accessory", icon: "sparkles") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                        ForEach(AvatarAccessory.allCases, id: \.self) { accessory in
                            optionButton(
                                label: accessory.rawValue.capitalized,
                                isSelected: viewModel.config.accessory == accessory
                            ) {
                                withAnimation(GQTheme.bouncyQuick) {
                                    viewModel.config.accessory = accessory
                                }
                            }
                        }
                    }
                }

                // Background Color
                sectionView(title: "Background", icon: "circle.fill") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                        ForEach(AvatarBackgroundColor.allCases, id: \.self) { bg in
                            optionButton(
                                label: bg.rawValue.replacingOccurrences(of: "light", with: "").capitalized,
                                isSelected: viewModel.config.backgroundColor == bg
                            ) {
                                withAnimation(GQTheme.bouncyQuick) {
                                    viewModel.config.backgroundColor = bg
                                }
                            }
                        }
                    }
                }

                // Save button
                GQButton(
                    title: "Save Avatar",
                    icon: "checkmark.circle.fill",
                    color: GQTheme.success,
                    isLoading: viewModel.isSaving
                ) {
                    Task {
                        guard let userId = appState.currentUser?.id else { return }
                        await viewModel.save(userId: userId, appState: appState)
                    }
                }
            }
            .padding(GQTheme.paddingLarge)
        }
        .toast(isPresented: Binding(
            get: { viewModel.showSavedToast },
            set: { viewModel.showSavedToast = $0 }
        ), message: "Avatar saved!")
    }

    // MARK: - Helpers

    private func sectionView<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(GQTheme.accent)
                Text(title)
                    .font(GQTheme.headlineFont)
            }
            content()
        }
    }

    private func colorCircle(color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 3)
                        .frame(width: 40, height: 40)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(BouncyScaleStyle())
    }

    private func optionButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(GQTheme.captionFont.weight(.medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    isSelected ? GQTheme.accent : GQTheme.cardBackground,
                    in: RoundedRectangle(cornerRadius: GQTheme.cornerRadiusSmall)
                )
        }
        .buttonStyle(BouncyScaleStyle())
    }

    private func bodySwiftUIColor(_ color: AvatarBodyColor) -> Color {
        switch color {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        case .teal: return .teal
        case .mint: return .mint
        case .cyan: return .cyan
        case .brown: return .brown
        }
    }
}
