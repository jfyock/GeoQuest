#if DEBUG
import SwiftUI

/// On-screen arrow pad + keyboard arrow key handler for testing avatar movement
/// without physically walking. Only visible in DEBUG builds.
struct DebugMovementOverlay: View {
    let locationService: LocationService
    @State private var isExpanded = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            if isExpanded {
                debugPad
                    .transition(.scale.combined(with: .opacity))
            }

            HStack {
                Spacer()
                Button {
                    withAnimation(GQTheme.bouncyQuick) {
                        isExpanded.toggle()
                        if !isExpanded {
                            locationService.exitSimulation()
                        }
                    }
                } label: {
                    Image(systemName: isExpanded ? "xmark.circle.fill" : "arrow.up.and.down.and.arrow.left.and.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(isExpanded ? .red : .white)
                        .frame(width: 40, height: 40)
                        .background(
                            isExpanded ? Color.red.opacity(0.15) : GQTheme.primary.opacity(0.85),
                            in: Circle()
                        )
                        .overlay(
                            Circle().stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(BouncyButtonStyle())
                .padding(.trailing, GQTheme.paddingMedium)
                .padding(.bottom, GQTheme.paddingSmall)
            }
        }
        .focusable()
        .focused($isFocused)
        .onKeyPress(.upArrow) { move(.north); return .handled }
        .onKeyPress(.downArrow) { move(.south); return .handled }
        .onKeyPress(.leftArrow) { move(.west); return .handled }
        .onKeyPress(.rightArrow) { move(.east); return .handled }
        .onAppear { isFocused = true }
    }

    // MARK: - Arrow Pad

    private var debugPad: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("DEBUG MOVEMENT")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
            }
            .padding(.bottom, 4)

            // Up
            arrowButton(direction: .north, icon: "arrow.up", label: "N")

            // Left / Stop / Right
            HStack(spacing: 12) {
                arrowButton(direction: .west, icon: "arrow.left", label: "W")

                Button {
                    locationService.simulateStop()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.orange)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(BouncyButtonStyle())

                arrowButton(direction: .east, icon: "arrow.right", label: "E")
            }

            // Down
            arrowButton(direction: .south, icon: "arrow.down", label: "S")
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal, GQTheme.paddingLarge)
        .padding(.bottom, 4)
    }

    private func arrowButton(direction: LocationService.SimulatedDirection, icon: String, label: String) -> some View {
        Button { move(direction) } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                Text(label)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(GQTheme.primary.opacity(0.7), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(BouncyButtonStyle())
    }

    private func move(_ direction: LocationService.SimulatedDirection) {
        locationService.simulateMovement(direction: direction)
    }
}
#endif
