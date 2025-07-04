import SwiftUI

/// A modal view that explains why Google Sign-In is used in the app.
/// Features an animated interface with security and privacy information.
struct WhyGoogleModal: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.6).delay(0.1), value: animateContent)
            
            // Header section with icon
            VStack(spacing: 24) {
                // Modern icon treatment
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .scaleEffect(animateContent ? 1.0 : 0.6)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.accentColor)
                        .scaleEffect(animateContent ? 1.0 : 0.4)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                .animation(.easeOut(duration: 1.0).delay(0.3), value: animateContent)
                
                // Title
                Text("Why Google Access?")
                    .font(.sora(.bold, size: 24))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: animateContent)
            }
            .padding(.top, 24)
            
            // Content sections
            ScrollView {
                VStack(spacing: 24) {
                    // Apple + Google explanation
                    InfoSection(
                        icon: "person.badge.shield.checkmark",
                        iconColor: .blue,
                        title: "Apple ID for Identity",
                        description: "Your Apple ID securely identifies you and provides basic profile information. No payment details are shared.",
                        animateContent: animateContent,
                        delay: 0.8
                    )
                    
                    // Data section
                    InfoSection(
                        icon: "chart.bar.fill",
                        iconColor: .accentColor,
                        title: "Google for AdSense Data",
                        description: "Google OAuth provides secure access to your AdSense account data for accurate earnings and performance analytics.",
                        animateContent: animateContent,
                        delay: 1.0
                    )
                    
                    // Privacy section
                    InfoSection(
                        icon: "hand.raised.fill",
                        iconColor: .purple,
                        title: "No Data Storage",
                        description: "AdRadar doesn't store your personal information. Data is only used to display your analytics and is never shared.",
                        animateContent: animateContent,
                        delay: 1.2
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }
            
            // Action button
            VStack(spacing: 16) {
                Button(action: { 
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    isPresented = false 
                }) {
                    Text("Got it!")
                        .font(.sora(.semibold, size: 17))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ModernButtonStyle())
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.6).delay(1.6), value: animateContent)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                animateContent = true
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    WhyGoogleModal(isPresented: .constant(true))
} 