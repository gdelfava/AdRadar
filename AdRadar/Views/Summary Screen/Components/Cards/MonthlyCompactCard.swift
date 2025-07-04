import SwiftUI

/// A compact card component specifically designed for displaying monthly metrics.
/// Features a vertical layout with icon, title, value, and delta indicator.
struct MonthlyCompactCard: View {
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
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .soraSubheadline()
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(value)
                    .soraTitle3()
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let delta = delta, let positive = deltaPositive {
                    HStack(spacing: 4) {
                        Image(systemName: positive ? "arrow.up" : "arrow.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(positive ? .green : .red)
                        
                        Text(delta)
                            .soraCaption2()
                            .foregroundColor(positive ? .green : .red)
                    }
                } else {
                    // Spacer to maintain consistent height
                    Text(" ")
                        .soraCaption2()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: color.opacity(0.08), location: 0),
                    .init(color: color.opacity(0.04), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .scaleEffect(isPressed ? 0.96 : 1.0)
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
    HStack {
        MonthlyCompactCard(
            title: "This Month",
            value: "$12,345.67",
            subtitle: "vs same day last month",
            delta: "+8.5%",
            deltaPositive: true,
            icon: "calendar",
            color: .purple
        )
        
        MonthlyCompactCard(
            title: "Last Month",
            value: "$11,234.56",
            subtitle: "vs previous month",
            delta: "-2.1%",
            deltaPositive: false,
            icon: "calendar.badge.minus",
            color: .pink
        )
    }
    .padding()
    .background(Color(.systemBackground))
} 