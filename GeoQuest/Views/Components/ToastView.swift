import SwiftUI

struct ToastView: View {
    let message: String
    var icon: String = "checkmark.circle.fill"
    var color: Color = GQTheme.success

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(message)
                .font(GQTheme.captionFont)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, GQTheme.paddingMedium)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .gqShadow()
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
