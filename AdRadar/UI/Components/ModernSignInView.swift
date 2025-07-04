import SwiftUI
import GoogleSignIn
import UIKit

/// A modern, animated sign-in view that provides Google authentication.
/// Features a clean design with animated elements, branding, and a Google Sign-In button.
struct ModernSignInView: View {
    let authViewModel: AuthViewModel
    @Binding var showWhyGoogle: Bool
    @State private var animateContent = false
    @State private var showSignInButton = false
    @State private var animateFloatingElements = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Modern gradient background
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
                
                // Floating elements for visual interest
                FloatingElementsView(animate: $animateFloatingElements)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Top spacing
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: max(geometry.safeAreaInsets.top + 10, 20))
                        
                        // Main content
                        VStack(spacing: 32) {
                            // Header section
                            VStack(spacing: 24) {
                                // App branding with modern circles (no icon)
                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.1))
                                        .frame(width: 200, height: 200)
                                        .scaleEffect(animateContent ? 1.0 : 0.8)
                                        .opacity(animateContent ? 1.0 : 0.0)
                                    
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.15))
                                        .frame(width: 160, height: 160)
                                        .scaleEffect(animateContent ? 1.0 : 0.6)
                                        .opacity(animateContent ? 1.0 : 0.0)
                                    
                                    // Central radar icon
                                    ZStack {
                                        Circle()
                                            .fill(Color.accentColor.opacity(0.9))
                                            .frame(width: 100, height: 100)
                                        
                                        Image(systemName: "target")
                                            .font(.system(size: 40, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .scaleEffect(animateContent ? 1.0 : 0.4)
                                    .opacity(animateContent ? 1.0 : 0.0)
                                    
                                    // Pulsing effect
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.3))
                                        .frame(width: 100, height: 100)
                                        .scaleEffect(animateContent ? 1.4 : 0.4)
                                        .opacity(animateContent ? 0.0 : 0.8)
                                        .animation(.easeOut(duration: 2.0).repeatForever(autoreverses: true), value: animateContent)
                                }
                                .animation(.easeOut(duration: 1.2).delay(0.3), value: animateContent)
                                
                                // App title and description
                                VStack(spacing: 16) {
                                    VStack(spacing: 8) {
                                        Text("AdRadar")
                                            .font(.sora(.bold, size: 48))
                                            .foregroundColor(.primary)
                                            .opacity(animateContent ? 1.0 : 0.0)
                                            .offset(y: animateContent ? 0 : 30)
                                            .animation(.easeOut(duration: 0.8).delay(0.8), value: animateContent)
                                        
                                        // Text("for AdSense & AdMob") - Removed as requested
                                    }
                                    
                                    Text("Track your ads income and payments with beautiful analytics and detailed insights")
                                        .font(.sora(.regular, size: 18))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 40)
                                        .opacity(animateContent ? 1.0 : 0.0)
                                        .offset(y: animateContent ? 0 : 30)
                                        .animation(.easeOut(duration: 0.8).delay(1.2), value: animateContent)
                                }
                            }
                            
                            // Spacer to push sign-in button to bottom
                            Spacer()
                            
                            // Sign in section
                            VStack(spacing: 16) {
                                // Apple Sign In Button or Transition Loading
                                if authViewModel.isTransitioningToGoogle {
                                    // Transition loading state
                                    VStack(spacing: 12) {
                                        HStack(spacing: 16) {
                                            ProgressView()
                                                .scaleEffect(1.2)
                                            
                                            Text("Connecting to Google...")
                                                .font(.sora(.semibold, size: 17))
                                                .foregroundColor(.primary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .shadow(color: Color.primary.opacity(0.1), radius: 12, x: 0, y: 4)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                        )
                                        
                                        Text("Please wait while we connect to your Google account for AdSense access")
                                            .font(.sora(.regular, size: 14))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .fixedSize(horizontal: false, vertical: true)
                                        
                                        // Cancel button for if it gets stuck
                                        Button("Cancel") {
                                            authViewModel.isTransitioningToGoogle = false
                                        }
                                        .font(.sora(.medium, size: 14))
                                        .foregroundColor(.red)
                                        .padding(.top, 8)
                                    }
                                } else {
                                    // Apple Sign In Button
                                    AppleSignInButton(action: {
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                        impactFeedback.impactOccurred()
                                        authViewModel.signInWithApple()
                                    })
                                    .scaleEffect(showSignInButton ? 1.0 : 0.8)
                                    .opacity(showSignInButton ? 1.0 : 0.0)
                                    .animation(.easeOut(duration: 0.6).delay(1.4), value: showSignInButton)
                                }
                                
                                // Divider with "OR"
                                HStack {
                                    Rectangle()
                                        .fill(Color.primary.opacity(0.2))
                                        .frame(height: 1)
                                    
                                    Text("OR")
                                        .font(.sora(.medium, size: 14))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 16)
                                    
                                    Rectangle()
                                        .fill(Color.primary.opacity(0.2))
                                        .frame(height: 1)
                                }
                                .scaleEffect(showSignInButton ? 1.0 : 0.8)
                                .opacity(showSignInButton ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.6).delay(1.45), value: showSignInButton)
                                
                                // Google Sign In Button (for users who prefer direct Google auth)
                                Button(action: {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    authViewModel.signIn()
                                }) {
                                    HStack(spacing: 16) {
                                        // Google Sign In icon
                                        Image("GoogleSignIn")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 24)
                                        
                                        Text("Continue with Google")
                                            .font(.sora(.semibold, size: 17))
                                            .foregroundColor(.primary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .shadow(color: Color.primary.opacity(0.1), radius: 12, x: 0, y: 4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(ModernButtonStyle())
                                .scaleEffect(showSignInButton ? 1.0 : 0.8)
                                .opacity(showSignInButton ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.6).delay(1.5), value: showSignInButton)
                                
                                // Demo Mode Button
                                Button(action: {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    authViewModel.enterDemoMode()
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.accentColor)
                                        
                                        Text("Try Demo Mode")
                                            .font(.sora(.semibold, size: 17))
                                            .foregroundColor(.accentColor)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.accentColor.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(ModernButtonStyle())
                                .scaleEffect(showSignInButton ? 1.0 : 0.8)
                                .opacity(showSignInButton ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.6).delay(1.55), value: showSignInButton)
                                
                                // Info text
                                Button(action: { 
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    showWhyGoogle = true 
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "info.circle")
                                            .font(.system(size: 14, weight: .medium))
                                        Text("Why do I need Google access?")
                                            .font(.sora(.medium, size: 14))
                                    }
                                    .foregroundColor(.secondary)
                                }
                                .opacity(showSignInButton ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.6).delay(1.65), value: showSignInButton)
                            }
                            .padding(.horizontal, 32)
                        }
                        
                        // Bottom spacing
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: max(geometry.safeAreaInsets.bottom + 50, 80))
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateContent = true
                animateFloatingElements = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(2.0)) {
                showSignInButton = true
            }
        }
    }
}

#Preview {
    ModernSignInView(
        authViewModel: AuthViewModel(),
        showWhyGoogle: .constant(false)
    )
} 
