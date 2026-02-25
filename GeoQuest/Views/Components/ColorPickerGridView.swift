import SwiftUI

struct ColorPickerGridView: View {
    @Binding var selectedColorHex: String

    private let presetColors: [(name: String, hex: String)] = [
        ("Red", "FF3B30"),
        ("Orange", "FF9500"),
        ("Yellow", "FFCC00"),
        ("Green", "34C759"),
        ("Teal", "5AC8FA"),
        ("Blue", "007AFF"),
        ("Indigo", "5856D6"),
        ("Purple", "AF52DE"),
        ("Pink", "FF2D55"),
        ("Brown", "A2845E"),
        ("Mint", "00C7BE"),
        ("Cyan", "32D2FF"),
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(presetColors, id: \.hex) { preset in
                Button {
                    withAnimation(GQTheme.bouncyQuick) {
                        selectedColorHex = preset.hex
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: preset.hex))
                            .frame(width: 40, height: 40)

                        if selectedColorHex == preset.hex {
                            Circle()
                                .strokeBorder(.white, lineWidth: 3)
                                .frame(width: 40, height: 40)
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(BouncyScaleStyle())
            }
        }
    }
}
