import SwiftUI

/// A large hero card component that displays the main summary metrics with animations and modern styling.
/// Features a gradient background, pattern overlay, and interactive tap feedback.
struct HeroSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let delta: String?
    let deltaPositive: Bool?
    var onTap: (() -> Void)? = nil
    
    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content
            VStack(alignment: .leading, spacing: 20) {
                // Header with icon
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.green.opacity(0.2),
                                            Color.green.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "calendar.circle.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .soraTitle3()
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
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Main value
                VStack(alignment: .leading, spacing: 12) {
                    Text(value)
                        .soraFont(.bold, size: 36)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    // Delta indicator with improved layout
                    if let delta = delta, let positive = deltaPositive {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: positive ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
                                    .foregroundColor(positive ? .green : .red)
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Text(delta)
                                    .soraSubheadline()
                                    .foregroundColor(positive ? .green : .red)
                                
                                Spacer()
                            }
                            
                            Text("compared to yesterday")
                                .soraCaption()
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill((positive ? Color.green : Color.red).opacity(0.1))
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(
            ZStack {
                // Base gradient
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.green.opacity(0.08), location: 0),
                        .init(color: Color.green.opacity(0.04), location: 0.5),
                        .init(color: Color.green.opacity(0.02), location: 1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Pattern overlay
                PatternOverlay(color: .green.opacity(0.03))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.green.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 20, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.green.opacity(0.2),
                            Color.clear,
                            Color.green.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
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
    HeroSummaryCard(
        title: "Today So Far",
        value: "$1,234.56",
        subtitle: "vs yesterday",
        delta: "+15.2%",
        deltaPositive: true
    )
    .padding()
    .background(Color(.systemBackground))
} 