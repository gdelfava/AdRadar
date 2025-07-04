import SwiftUI

/// Modern menu row with premium indicator
struct ModernMenuRowWithPremium: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let isPremium: Bool
    let action: () -> Void
    
    @State private var showUpgradeSheet = false
    @EnvironmentObject private var premiumStatusManager: PremiumStatusManager
    
    var body: some View {
        Button(action: {
            if isPremium && !premiumStatusManager.hasFeature(.advancedAnalytics) {
                showUpgradeSheet = true
            } else {
                action()
            }
        }) {
            HStack(spacing: 16) {
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(iconColor.opacity(isPremium ? 0.1 : 0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isPremium ? iconColor.opacity(0.6) : iconColor)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .soraSubheadline()
                            .fontWeight(.medium)
                            .foregroundColor(isPremium ? .secondary : .primary)
                        
                        if isPremium {
                            PremiumBadge()
                        }
                    }
                    
                    Text(isPremium ? "Upgrade to Premium to unlock" : subtitle)
                        .soraCaption()
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Arrow or lock icon
                Image(systemName: isPremium ? "lock.fill" : "chevron.right")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showUpgradeSheet) {
            PremiumUpgradeView()
        }
    }
}

/// Analytics section of the slide over menu
struct AnalyticsMenuSection: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @EnvironmentObject var premiumStatusManager: PremiumStatusManager
    @EnvironmentObject var authViewModel: AuthViewModel
    let onDismiss: () -> Void
    @Binding var showDomainsView: Bool
    @Binding var showAdSizeView: Bool
    @Binding var showPlatformsView: Bool
    @Binding var showCountriesView: Bool
    @Binding var showAdNetworkView: Bool
    @Binding var showTargetingView: Bool
    @Binding var showAppsView: Bool
    
    var body: some View {
        MenuSection(title: "Analytics", icon: "chart.bar.fill", iconColor: .blue) {
            ModernMenuRow(
                icon: "globe.americas.fill", 
                title: "Domains", 
                subtitle: "Site performance",
                iconColor: .blue,
                action: {
                    hapticFeedback()
                    showDomainsView = true
                    onDismiss()
                }
            )
            
            VStack {
                if authViewModel.isDemoMode {
                    ModernMenuRow(
                        icon: "rectangle.3.group.fill", 
                        title: "Ad Sizes", 
                        subtitle: "Format metrics",
                        iconColor: .purple,
                        action: {
                            hapticFeedback()
                            showAdSizeView = true
                            onDismiss()
                        }
                    )
                } else if premiumStatusManager.hasFeature(.advancedAnalytics) {
                    ModernMenuRow(
                        icon: "rectangle.3.group.fill", 
                        title: "Ad Sizes", 
                        subtitle: "Format metrics",
                        iconColor: .purple,
                        action: {
                            hapticFeedback()
                            showAdSizeView = true
                            onDismiss()
                        }
                    )
                } else {
                    ModernMenuRowWithPremium(
                        icon: "rectangle.3.group.fill", 
                        title: "Ad Sizes", 
                        subtitle: "Format metrics",
                        iconColor: .purple,
                        isPremium: true,
                        action: {
                            hapticFeedback()
                            premiumStatusManager.trackFeatureUsage(.advancedAnalytics)
                        }
                    )
                }
            }
            
            VStack {
                if authViewModel.isDemoMode {
                    ModernMenuRow(
                        icon: "iphone", 
                        title: "Platforms", 
                        subtitle: "Device breakdown",
                        iconColor: .green,
                        action: {
                            hapticFeedback()
                            showPlatformsView = true
                            onDismiss()
                        }
                    )
                } else if premiumStatusManager.hasFeature(.advancedAnalytics) {
                    ModernMenuRow(
                        icon: "iphone", 
                        title: "Platforms", 
                        subtitle: "Device breakdown",
                        iconColor: .green,
                        action: {
                            hapticFeedback()
                            showPlatformsView = true
                            onDismiss()
                        }
                    )
                } else {
                    ModernMenuRowWithPremium(
                        icon: "iphone", 
                        title: "Platforms", 
                        subtitle: "Device breakdown",
                        iconColor: .green,
                        isPremium: true,
                        action: {
                            hapticFeedback()
                            premiumStatusManager.trackFeatureUsage(.advancedAnalytics)
                        }
                    )
                }
            }
            
            VStack {
                if authViewModel.isDemoMode {
                    ModernMenuRow(
                        icon: "flag.fill", 
                        title: "Countries", 
                        subtitle: "Geographic data",
                        iconColor: .orange,
                        action: {
                            hapticFeedback()
                            showCountriesView = true
                            onDismiss()
                        }
                    )
                } else if premiumStatusManager.hasFeature(.advancedAnalytics) {
                    ModernMenuRow(
                        icon: "flag.fill", 
                        title: "Countries", 
                        subtitle: "Geographic data",
                        iconColor: .orange,
                        action: {
                            hapticFeedback()
                            showCountriesView = true
                            onDismiss()
                        }
                    )
                } else {
                    ModernMenuRowWithPremium(
                        icon: "flag.fill", 
                        title: "Countries", 
                        subtitle: "Geographic data",
                        iconColor: .orange,
                        isPremium: true,
                        action: {
                            hapticFeedback()
                            premiumStatusManager.trackFeatureUsage(.advancedAnalytics)
                        }
                    )
                }
            }
            
            VStack {
                if authViewModel.isDemoMode {
                    ModernMenuRow(
                        icon: "network", 
                        title: "Ad Networks", 
                        subtitle: "Network performance",
                        iconColor: .indigo,
                        action: {
                            hapticFeedback()
                            showAdNetworkView = true
                            onDismiss()
                        }
                    )
                } else if premiumStatusManager.hasFeature(.advancedAnalytics) {
                    ModernMenuRow(
                        icon: "network", 
                        title: "Ad Networks", 
                        subtitle: "Network performance",
                        iconColor: .indigo,
                        action: {
                            hapticFeedback()
                            showAdNetworkView = true
                            onDismiss()
                        }
                    )
                } else {
                    ModernMenuRowWithPremium(
                        icon: "network", 
                        title: "Ad Networks", 
                        subtitle: "Network performance",
                        iconColor: .indigo,
                        isPremium: true,
                        action: {
                            hapticFeedback()
                            premiumStatusManager.trackFeatureUsage(.advancedAnalytics)
                        }
                    )
                }
            }
            
            VStack {
                if authViewModel.isDemoMode {
                    ModernMenuRow(
                        icon: "target", 
                        title: "Targeting", 
                        subtitle: "Type performance",
                        iconColor: .pink,
                        action: {
                            hapticFeedback()
                            showTargetingView = true
                            onDismiss()
                        }
                    )
                } else if premiumStatusManager.hasFeature(.advancedAnalytics) {
                    ModernMenuRow(
                        icon: "target", 
                        title: "Targeting", 
                        subtitle: "Type performance",
                        iconColor: .pink,
                        action: {
                            hapticFeedback()
                            showTargetingView = true
                            onDismiss()
                        }
                    )
                } else {
                    ModernMenuRowWithPremium(
                        icon: "target", 
                        title: "Targeting", 
                        subtitle: "Type performance",
                        iconColor: .pink,
                        isPremium: true,
                        action: {
                            hapticFeedback()
                            premiumStatusManager.trackFeatureUsage(.advancedAnalytics)
                        }
                    )
                }
            }
            
            if settingsViewModel.showAdMobApps {
                ModernMenuRow(
                    icon: "apps.iphone", 
                    title: "AdMob Apps", 
                    subtitle: "Mobile app metrics",
                    iconColor: .cyan,
                    action: {
                        hapticFeedback()
                        showAppsView = true
                        onDismiss()
                    }
                )
            }
        }
    }
    
    private func hapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

/// Account section of the slide over menu
struct AccountMenuSection: View {
    @Binding var selectedTab: Int
    let onDismiss: () -> Void
    
    var body: some View {
        MenuSection(title: "Account", icon: "person.circle.fill", iconColor: .green) {
            ModernMenuRow(
                icon: "creditcard.fill", 
                title: "Payments", 
                subtitle: "Earnings & history",
                iconColor: .green,
                action: {
                    hapticFeedback()
                    selectedTab = 2
                    onDismiss()
                }
            )
            
            ModernMenuRow(
                icon: "gearshape.fill", 
                title: "Settings", 
                subtitle: "App preferences",
                iconColor: .gray,
                action: {
                    hapticFeedback()
                    selectedTab = 3
                    onDismiss()
                }
            )
        }
    }
    
    private func hapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

/// Support section of the slide over menu
struct SupportMenuSection: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showMail: Bool
    
    var body: some View {
        MenuSection(title: "Support", icon: "questionmark.circle.fill", iconColor: .orange) {
            ModernMenuRow(
                icon: "envelope.fill", 
                title: "Send Feedback", 
                subtitle: "Help us improve",
                iconColor: .blue,
                action: {
                    hapticFeedback()
                    showMail = true
                }
            )
            
            // TODO: Re-enable when app is published to App Store
            /*
            ModernMenuRow(
                icon: "star.fill", 
                title: "Rate App", 
                subtitle: "Share your experience",
                iconColor: .yellow,
                action: {
                    hapticFeedback()
                    if let url = URL(string: "https://apps.apple.com/us/app/myads-adsense-admob/id1481431267?action=write-review") {
                        UIApplication.shared.open(url)
                    }
                }
            )
            */
            
            ModernMenuRow(
                icon: "rectangle.portrait.and.arrow.right", 
                title: "Sign Out", 
                subtitle: "Exit your account",
                iconColor: .red,
                action: {
                    hapticFeedback()
                    authViewModel.signOut()
                }
            )
        }
    }
    
    private func hapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

#Preview {
    VStack(spacing: 20) {
        AnalyticsMenuSection(
            onDismiss: {},
            showDomainsView: .constant(false),
            showAdSizeView: .constant(false),
            showPlatformsView: .constant(false),
            showCountriesView: .constant(false),
            showAdNetworkView: .constant(false),
            showTargetingView: .constant(false),
            showAppsView: .constant(false)
        )
        .environmentObject(SettingsViewModel(authViewModel: AuthViewModel()))
        
        AccountMenuSection(selectedTab: .constant(0), onDismiss: {})
        
        SupportMenuSection(showMail: .constant(false))
            .environmentObject(AuthViewModel())
    }
    .padding()
} 