import SwiftUI

struct QuestStepEditorView: View {
    let stepNumber: Int
    @Binding var instruction: String
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number badge
            Text("\(stepNumber)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(GQTheme.accent, in: Circle())

            // Instruction text field
            VStack(alignment: .trailing, spacing: 4) {
                TextField("Describe this step...", text: $instruction, axis: .vertical)
                    .font(GQTheme.bodyFont)
                    .lineLimit(3...5)
                    .padding(12)
                    .background(GQTheme.cardBackground, in: RoundedRectangle(cornerRadius: GQTheme.cornerRadiusSmall))

                Text("\(instruction.count)/\(AppConstants.maxStepCharacters)")
                    .font(GQTheme.caption2Font)
                    .foregroundStyle(.tertiary)
            }
            .onChange(of: instruction) { _, newValue in
                if newValue.count > AppConstants.maxStepCharacters {
                    instruction = String(newValue.prefix(AppConstants.maxStepCharacters))
                }
            }

            // Delete button
            if canDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(BouncyButtonStyle())
            }
        }
    }
}
