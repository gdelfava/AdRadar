import SwiftUI
import MessageUI

struct SlideOverMenuView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Binding var selectedTab: Int // 0: Summary, 1: Streak, 2: Payments, 3: Settings
    @Binding var showDomainsView: Bool
    @Binding var showAdSizeView: Bool
    @Binding var showPlatformsView: Bool
    @Binding var showCountriesView: Bool
    @Binding var showAdNetworkView: Bool
    @Binding var showTargetingView: Bool
    @Binding var showAppsView: Bool
    @State private var showMail = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Menu content
                VStack(spacing: 0) {
                    // Header with user info
                    MenuHeaderView(geometry: geometry, onDismiss: dismissMenu)
                    
                    // Main content with modern sections
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Analytics Section
                            AnalyticsMenuSection(
                                onDismiss: dismissMenu,
                                showDomainsView: $showDomainsView,
                                showAdSizeView: $showAdSizeView,
                                showPlatformsView: $showPlatformsView,
                                showCountriesView: $showCountriesView,
                                showAdNetworkView: $showAdNetworkView,
                                showTargetingView: $showTargetingView,
                                showAppsView: $showAppsView
                            )
                            
                            // Account Section
                            AccountMenuSection(selectedTab: $selectedTab, onDismiss: dismissMenu)
                            
                            // Support Section
                            SupportMenuSection(showMail: $showMail)
                            
                            // Bottom spacing
                            Spacer()
                                .frame(height: 48)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    }
                    .background(Color(.systemGroupedBackground))
                }
                .frame(width: min(geometry.size.width * 0.85, 340), height: geometry.size.height)
                .background(Color(.systemGroupedBackground))
                .clipShape(
                    RoundedCornerShape(
                        radius: 0,
                        corners: [.topRight, .bottomRight]
                    )
                )
                .shadow(color: .black.opacity(0.15), radius: 20, x: 5, y: 0)
                
                // Dismiss area
                Color.black.opacity(0.4)
                    .onTapGesture {
                        dismissMenu()
                    }
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showMail) {
            MailView(
                toRecipients: ["apps@delteqis.co.za"],
                subject: "AdRadar: User feedback",
                body: "Any feedback or questions are more than welcome, please enter your message below:",
                completion: { _ in showMail = false }
            )
        }
    }
    
    private func dismissMenu() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

#Preview {
    SlideOverMenuView(isPresented: .constant(true), selectedTab: .constant(0), showDomainsView: .constant(false), showAdSizeView: .constant(false), showPlatformsView: .constant(false), showCountriesView: .constant(false), showAdNetworkView: .constant(false), showTargetingView: .constant(false), showAppsView: .constant(false))
        .environmentObject(AuthViewModel())
        .environmentObject(SettingsViewModel(authViewModel: AuthViewModel()))
} 