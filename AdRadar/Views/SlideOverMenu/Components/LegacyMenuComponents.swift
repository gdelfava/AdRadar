import SwiftUI

/// Legacy menu row component for compatibility
struct MenuRow: View {
    let icon: String
    let title: String
    var color: Color = .primary
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24)
            Text(title)
                .soraBody()
                .foregroundColor(color)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

/// Legacy menu item component for compatibility
struct MenuItemView: View {
    let title: String
    let icon: String
    
    var body: some View {
        Button(action: {
            // Handle menu item tap
            print("Tapped: \(title)")
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 24)
                
                Text(title)
                    .soraBody()
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        MenuRow(icon: "house.fill", title: "Home")
        MenuItemView(title: "Settings", icon: "gearshape.fill")
    }
    .padding()
} 