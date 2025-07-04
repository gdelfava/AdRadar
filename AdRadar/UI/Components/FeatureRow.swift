import SwiftUI

/// A reusable row component that displays a feature with an icon, title, and description.
/// Used across the app to present features in a consistent, animated way.
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.accentColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.sora(.semibold, size: 16))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.sora(.regular, size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(animate ? 1.0 : 0.0)
        .offset(x: animate ? 0 : -30)
        .animation(.easeOut(duration: 0.6).delay(delay), value: animate)
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        FeatureRow(
            icon: "chart.bar.fill",
            title: "Analytics",
            description: "Track your earnings with detailed insights",
            delay: 0.2
        )
        FeatureRow(
            icon: "bell.fill",
            title: "Notifications",
            description: "Stay updated with important alerts",
            delay: 0.4
        )
    }
    .padding()
} 