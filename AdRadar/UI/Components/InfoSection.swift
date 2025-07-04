import SwiftUI

/// A reusable section component that displays information with an icon, title, and description.
/// Features smooth animations and consistent styling across the app.
struct InfoSection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let animateContent: Bool
    let delay: Double
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.sora(.semibold, size: 16))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.sora(.regular, size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 30)
        .animation(.easeOut(duration: 0.8).delay(delay), value: animateContent)
    }
}

#Preview {
    VStack(spacing: 16) {
        InfoSection(
            icon: "lock.shield",
            iconColor: .green,
            title: "Security",
            description: "Your data is protected with industry-standard encryption.",
            animateContent: true,
            delay: 0.2
        )
        InfoSection(
            icon: "hand.raised.fill",
            iconColor: .purple,
            title: "Privacy",
            description: "We never share your personal information with third parties.",
            animateContent: true,
            delay: 0.4
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
} 