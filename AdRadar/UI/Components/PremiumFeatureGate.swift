import SwiftUI

struct PremiumFeatureGate<Content: View>: View {
    let feature: PremiumStatusManager.PremiumFeature
    let content: () -> Content
    @EnvironmentObject private var premiumStatusManager: PremiumStatusManager
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showUpgradeSheet = false
    
    init(feature: PremiumStatusManager.PremiumFeature, @ViewBuilder content: @escaping () -> Content) {
        self.feature = feature
        self.content = content
    }
    
    var body: some View {
        Group {
            if authViewModel.isDemoMode {
                content()
            } else if premiumStatusManager.hasFeature(feature) {
                content()
            } else {
                // Show locked content with upgrade prompt
                ZStack {
                    // Blurred content preview
                    content()
                        .blur(radius: 3)
                        .disabled(true)
                        .overlay(
                            Color.black.opacity(0.1)
                        )
                    
                    // Upgrade prompt overlay
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: feature.iconName)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.accentColor)
                        }
                        
                        VStack(spacing: 8) {
                            Text(feature.displayName)
                                .soraHeadline()
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text("Upgrade to Premium to unlock this feature")
                                .soraBody()
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button("Upgrade Now") {
                            premiumStatusManager.trackFeatureUsage(feature)
                            showUpgradeSheet = true
                        }
                        .buttonStyle(PremiumButtonStyle())
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.regularMaterial)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
            }
        }
        .sheet(isPresented: $showUpgradeSheet) {
            PremiumUpgradeView()
        }
        .onTapGesture {
            if !premiumStatusManager.hasFeature(feature) {
                premiumStatusManager.trackFeatureUsage(feature)
                showUpgradeSheet = true
            }
        }
    }
}

struct PremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .soraSubheadline()
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentColor,
                                Color.accentColor.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Inline Premium Badge

struct PremiumBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.caption2)
                .foregroundColor(.accentColor)
            
            Text("PRO")
                .soraCaption2()
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.accentColor.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Premium Feature List Item

struct PremiumFeatureListItem: View {
    let feature: PremiumStatusManager.PremiumFeature
    let isUnlocked: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: isUnlocked ? "checkmark" : feature.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isUnlocked ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.displayName)
                    .soraSubheadline()
                    .fontWeight(.medium)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                Text(feature.description)
                    .soraCaption()
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if !isUnlocked {
                PremiumBadge()
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - View Extensions for Easy Usage

extension View {
    func premiumGated(feature: PremiumStatusManager.PremiumFeature) -> some View {
        PremiumFeatureGate(feature: feature) {
            self
        }
    }
    
    func premiumBadge(isVisible: Bool = true) -> some View {
        HStack {
            self
            if isVisible {
                PremiumBadge()
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Example usage
        Text("Regular content")
            .soraBody()
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        
        Text("Premium content")
            .soraBody()
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
            .premiumGated(feature: .advancedAnalytics)
        
        Text("Feature with badge")
            .soraBody()
            .premiumBadge()
    }
    .padding()
    .environmentObject(PremiumStatusManager.shared)
} 