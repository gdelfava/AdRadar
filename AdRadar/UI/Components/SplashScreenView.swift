import SwiftUI

struct SplashScreenView: View {
    @State private var animateBackground = false
    @State private var animateLogo = false
    @State private var animateText = false
    @State private var animateSubtext = false
    @State private var showContent = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color.accentColor.opacity(0.1),
                    Color(.systemBackground)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .scaleEffect(animateBackground ? 1.2 : 1.0)
            .opacity(animateBackground ? 1.0 : 0.8)
            .animation(.easeInOut(duration: 2.0), value: animateBackground)
            
            // Floating particles effect
            ParticlesView(animate: $animateBackground)
            
            VStack(spacing: 32) {
                Spacer()
                
                // App logo with animated circles
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.accentColor.opacity(0.2), lineWidth: 2)
                        .frame(width: 160, height: 160)
                        .scaleEffect(animateLogo ? 1.0 : 0.3)
                        .opacity(animateLogo ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 1.2).delay(0.3), value: animateLogo)
                    
                    // Middle ring
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateLogo ? 1.0 : 0.4)
                        .opacity(animateLogo ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 1.0).delay(0.5), value: animateLogo)
                    
                    // Inner circle with icon
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.9))
                            .frame(width: 80, height: 80)
                        
                        // App icon or target symbol
                        Image(systemName: "target")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(animateLogo ? 1.0 : 0.2)
                    .opacity(animateLogo ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.7), value: animateLogo)
                    
                    // Pulsing effect
                    Circle()
                        .fill(Color.accentColor.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .scaleEffect(animateLogo ? 1.4 : 0.2)
                        .opacity(animateLogo ? 0.0 : 0.8)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: true), value: animateLogo)
                }
                
                // App name and tagline
                VStack(spacing: 16) {
                    Text("AdRadar")
                        .font(.sora(.bold, size: 36))
                        .foregroundColor(.primary)
                        .opacity(animateText ? 1.0 : 0.0)
                        .offset(y: animateText ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(1.2), value: animateText)
                    
                    Text("Track your ads income and stats")
                        .font(.sora(.medium, size: 16))
                        .foregroundColor(.secondary)
                        .opacity(animateSubtext ? 1.0 : 0.0)
                        .offset(y: animateSubtext ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(1.5), value: animateSubtext)
                }
                
                Spacer()
                
                // Loading indicator
                VStack(spacing: 12) {
                    LoadingDotsView()
                        .opacity(animateSubtext ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.6).delay(2.0), value: animateSubtext)
                    
                    Text("Loading your data...")
                        .font(.sora(.regular, size: 14))
                        .foregroundColor(.secondary)
                        .opacity(animateSubtext ? 0.8 : 0.0)
                        .animation(.easeOut(duration: 0.6).delay(2.2), value: animateSubtext)
                }
                .padding(.bottom, 60)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private func startAnimationSequence() {
        // Start background animation immediately
        animateBackground = true
        
        // Stagger other animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            animateLogo = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            animateText = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            animateSubtext = true
        }
        
        // Automatically dismiss after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

// MARK: - Particles Effect
struct ParticlesView: View {
    @Binding var animate: Bool
    @State private var particles: [Particle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles, id: \.id) { particle in
                    Circle()
                        .fill(Color.accentColor.opacity(0.3))
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .scaleEffect(animate ? 1.0 : 0.0)
                        .opacity(animate ? particle.opacity : 0.0)
                        .animation(.easeInOut(duration: Double.random(in: 2.0...4.0)).delay(particle.delay), value: animate)
                }
            }
        }
        .onAppear {
            generateParticles()
        }
    }
    
    private func generateParticles() {
        particles = (0..<15).map { index in
            Particle(
                id: index,
                position: CGPoint(
                    x: CGFloat.random(in: 50...350),
                    y: CGFloat.random(in: 100...700)
                ),
                size: CGFloat.random(in: 4...12),
                opacity: Double.random(in: 0.2...0.6),
                delay: Double.random(in: 0...2.0)
            )
        }
    }
}

struct Particle {
    let id: Int
    let position: CGPoint
    let size: CGFloat
    let opacity: Double
    let delay: Double
}

// MARK: - Loading Dots Animation
struct LoadingDotsView: View {
    @State private var animateOne = false
    @State private var animateTwo = false
    @State private var animateThree = false
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 8, height: 8)
                .scaleEffect(animateOne ? 1.2 : 0.8)
                .opacity(animateOne ? 1.0 : 0.6)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: animateOne)
            
            Circle()
                .fill(Color.accentColor)
                .frame(width: 8, height: 8)
                .scaleEffect(animateTwo ? 1.2 : 0.8)
                .opacity(animateTwo ? 1.0 : 0.6)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.2), value: animateTwo)
            
            Circle()
                .fill(Color.accentColor)
                .frame(width: 8, height: 8)
                .scaleEffect(animateThree ? 1.2 : 0.8)
                .opacity(animateThree ? 1.0 : 0.6)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.4), value: animateThree)
        }
        .onAppear {
            animateOne = true
            animateTwo = true
            animateThree = true
        }
    }
}

// MARK: - Preview
#Preview {
    SplashScreenView()
} 
