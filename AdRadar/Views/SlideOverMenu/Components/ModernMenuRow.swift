import SwiftUI

/// Modern Menu Row with enhanced design
struct ModernMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    var isDisabled: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            if !isDisabled {
                action()
            }
        }) {
            HStack(spacing: 16) {
                // Icon with background
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isDisabled ? iconColor.opacity(0.4) : iconColor)
                    .frame(width: 40, height: 40)
                    .background((isDisabled ? iconColor.opacity(0.1) : iconColor.opacity(0.15)))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                // Text content
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .soraBody()
                        .foregroundColor(isDisabled ? .secondary : .primary)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .soraCaption()
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Chevron or disabled indicator
                if isDisabled {
                    Text("Soon")
                        .soraCaption2()
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing && !isDisabled
            }
        }, perform: {})
    }
}

#Preview {
    VStack {
        ModernMenuRow(
            icon: "chart.bar.fill",
            title: "Analytics",
            subtitle: "View performance metrics",
            iconColor: .blue,
            action: {}
        )
        
        ModernMenuRow(
            icon: "star.fill",
            title: "Premium Feature",
            subtitle: "Coming soon",
            iconColor: .yellow,
            isDisabled: true,
            action: {}
        )
    }
    .padding()
} 