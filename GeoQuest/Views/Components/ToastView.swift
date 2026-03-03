import SwiftUI

struct ToastView: View {
    let message: String
    var icon: String = "checkmark.circle.fill"
    var color: Color = GQTheme.success

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(color)
            Text(message)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.2), lineWidth: 1.5))
        .shadow(color: color.opacity(0.2), radius: 10, y: 4)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    var icon: String = "checkmark.circle.fill"
    var color: Color = GQTheme.success

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if isPresented {
                ToastView(message: message, icon: icon, color: color)
                    .padding(.top, 50)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(GQTheme.smooth) {
                                isPresented = false
                            }
                        }
                    }
            }
        }
        .animation(GQTheme.bouncy, value: isPresented)
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String, icon: String = "checkmark.circle.fill", color: Color = GQTheme.success) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message, icon: icon, color: color))
    }
}
