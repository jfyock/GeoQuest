import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: GQTheme.paddingMedium) {
                // Account section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Account")
                        .font(GQTheme.headlineFont)
                        .padding(.horizontal, 4)

                    if let user = appState.currentUser {
                        GQCard {
                            VStack(alignment: .leading, spacing: 8) {
                                settingsRow(icon: "envelope.fill", label: "Email", value: user.email)
                                Divider()
                                settingsRow(icon: "person.fill", label: "Display Name", value: user.displayName)
                                Divider()
                                settingsRow(icon: "mappin.circle.fill", label: "City", value: user.city.isEmpty ? "Not set" : user.city)
                            }
                        }
                    }
                }

                // App Info section
                VStack(alignment: .leading, spacing: 12) {
                    Text("App Info")
                        .font(GQTheme.headlineFont)
                        .padding(.horizontal, 4)

                    GQCard {
                        VStack(alignment: .leading, spacing: 8) {
                            settingsRow(icon: "info.circle.fill", label: "Version", value: AppConstants.appVersion)
                            Divider()
                            settingsRow(icon: "globe", label: "App", value: AppConstants.appName)
                        }
                    }
                }

                Spacer(minLength: 40)

                // Sign Out
                GQButton(title: "Sign Out", icon: "rectangle.portrait.and.arrow.right", color: GQTheme.error) {
                    appState.handleSignOut()
                }
            }
            .padding(GQTheme.paddingLarge)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func settingsRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(label)
                .font(GQTheme.bodyFont)
            Spacer()
            Text(value)
                .font(GQTheme.bodyFont)
                .foregroundStyle(.secondary)
        }
    }
}
