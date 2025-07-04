import SwiftUI

/// A reusable header component for sections that includes an icon and title.
/// Features a modern design with a colored icon and separator line.
struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Text(title)
                .soraHeadline()
                .foregroundColor(.primary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            
            Spacer(minLength: 8)
            
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5)
                .frame(maxWidth: 120)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SectionHeader(
            title: "Recent Performance",
            icon: "clock.fill",
            color: .orange
        )
        
        SectionHeader(
            title: "Monthly Overview",
            icon: "calendar.circle.fill",
            color: .purple
        )
        
        SectionHeader(
            title: "All Time",
            icon: "infinity.circle.fill",
            color: .indigo
        )
    }
    .padding()
    .background(Color(.systemBackground))
} 