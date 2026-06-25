import SwiftUI

/// A circular icon button that shows a floating label on long-press.
struct TooltipButton: View {
    let systemImage: String
    let tooltip: String
    let isActive: Bool
    let action: () -> Void

    @State private var showTooltip = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 36, height: 36)
                .foregroundStyle(isActive ? Color.accentColor : .secondary)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if showTooltip {
                Text(tooltip)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThickMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
                    .fixedSize()
                    .offset(y: -46)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                    .zIndex(999)
            }
        }
        .onLongPressGesture(minimumDuration: 0.4) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                showTooltip = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showTooltip = false
                }
            }
        }
    }
}
