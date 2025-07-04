import SwiftUI

/// A compact card component for displaying summary metrics in a horizontal layout.
/// Features an icon, title, value, and optional delta indicator.
struct CompactSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let delta: String?
    let deltaPositive: Bool?
    let icon: String
    let color: Color
    var onTap: (() -> Void)? = nil
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .soraSubheadline()
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .soraCaption2()
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Value and delta
            VStack(alignment: .trailing, spacing: 4) {
                Text(value)
                    .soraTitle3()
                    .foregroundColor(.primary)
                
                if let delta = delta, let positive = deltaPositive {
                    HStack(spacing: 4) {
                        Image(systemName: positive ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(positive ? .green : .red)
                        
                        Text(delta)
                            .soraCaption2()
                            .foregroundColor(positive ? .green : .red)
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            
            onTap?()
        }
    }
}

#Preview {
    CompactSummaryCard(
        title: "Yesterday",
        value: "$987.65",
        subtitle: "vs the same day last week",
        delta: "+12.3%",
        deltaPositive: true,
        icon: "calendar.badge.clock",
        color: .orange
    )
    .padding()
    .background(Color(.systemBackground))
} 