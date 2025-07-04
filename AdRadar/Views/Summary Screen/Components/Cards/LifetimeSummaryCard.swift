import SwiftUI

/// A card component for displaying lifetime or all-time metrics.
/// Features a modern design with gradient background and pattern overlay.
struct LifetimeSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String?
    var onTap: (() -> Void)? = nil
    
    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.indigo.opacity(0.2),
                                            Color.indigo.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "infinity.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.indigo)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .soraHeadline()
                                .foregroundColor(.primary)
                            
                            if let subtitle = subtitle {
                                Text(subtitle)
                                    .soraCaption()
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Value
                Text(value)
                    .soraFont(.bold, size: 28)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            .padding(20)
        }
        .background(
            ZStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.indigo.opacity(0.1), location: 0),
                        .init(color: Color.indigo.opacity(0.05), location: 0.7),
                        .init(color: Color.indigo.opacity(0.02), location: 1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                PatternOverlay(color: .indigo.opacity(0.02))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.indigo.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 12, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.indigo.opacity(0.1), lineWidth: 1)
        )
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
    LifetimeSummaryCard(
        title: "Last Three Years",
        value: "$543,210.98",
        subtitle: "AdRadar for Adsense"
    )
    .padding()
    .background(Color(.systemBackground))
} 