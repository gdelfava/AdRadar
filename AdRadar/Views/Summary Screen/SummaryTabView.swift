import SwiftUI
import UIKit
import Combine
import GoogleSignIn

struct SummaryTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var showSlideOverMenu = false
    @State private var selectedTab: Int = 0
    @State private var showDomainsView = false
    @State private var showAdSizeView = false
    @State private var showPlatformsView = false
    @State private var showCountriesView = false
    @State private var showAdNetworkView = false
    @State private var showTargetingView = false
    @State private var showAppsView = false
    @State private var isInitialized = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Main content area - Use ZStack with opacity to prevent view recreation
                ZStack {
                    // Demo mode indicator
                    if authViewModel.isDemoMode {
                        VStack {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.accentColor)
                                Text("Demo Mode")
                                    .font(.sora(.medium, size: 14))
                                    .foregroundColor(.accentColor)
                                Button(action: {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    authViewModel.exitDemoMode()
                                }) {
                                    Text("Exit")
                                        .font(.sora(.semibold, size: 14))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.accentColor)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(Capsule())
                            .padding(.top, 8)
                            
                            Spacer()
                        }
                        .zIndex(1)
                    }
                    
                    if isInitialized {
                        SummaryView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                            .environmentObject(settingsViewModel)
                            .opacity(selectedTab == 0 ? 1 : 0)
                            .allowsHitTesting(selectedTab == 0)
                        
                        StreakView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                            .environmentObject(settingsViewModel)
                            .opacity(selectedTab == 1 ? 1 : 0)
                            .allowsHitTesting(selectedTab == 1)
                        
                        PaymentsView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                            .environmentObject(settingsViewModel)
                            .opacity(selectedTab == 2 ? 1 : 0)
                            .allowsHitTesting(selectedTab == 2)
                        
                        SettingsView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                            .environmentObject(settingsViewModel)
                            .opacity(selectedTab == 3 ? 1 : 0)
                            .allowsHitTesting(selectedTab == 3)
                    } else {
                        // Loading state while initializing
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading...")
                                .font(.sora(.medium, size: 16))
                                .foregroundColor(.secondary)
                                .padding(.top, 12)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Custom Modern Tab Bar
                if isInitialized {
                    ModernTabBar(selectedTab: $selectedTab)
                }
            }
            .task {
                // Defer initialization to async context
                await initializeAsync()
            }
            
            // Slide-over menu
            if showSlideOverMenu {
                SlideOverMenuView(
                    isPresented: $showSlideOverMenu, 
                    selectedTab: $selectedTab,
                    showDomainsView: $showDomainsView,
                    showAdSizeView: $showAdSizeView,
                    showPlatformsView: $showPlatformsView,
                    showCountriesView: $showCountriesView,
                    showAdNetworkView: $showAdNetworkView,
                    showTargetingView: $showTargetingView,
                    showAppsView: $showAppsView
                )
                .environmentObject(authViewModel)
                .environmentObject(settingsViewModel)
                .transition(.move(edge: .leading))
                .zIndex(1)
                .gesture(
                    DragGesture(minimumDistance: 15, coordinateSpace: .global)
                        .onEnded { value in
                            // Only trigger if drag is leftward and starts near left edge of menu
                            if value.translation.width < -20 && abs(value.translation.height) < 40 {
                                withAnimation { showSlideOverMenu = false }
                            }
                        }
                )
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.1), value: showSlideOverMenu)
        .fullScreenCover(isPresented: $showDomainsView) {
            DomainsView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showAdSizeView) {
            AdSizeView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showPlatformsView) {
            PlatformView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showCountriesView) {
            CountriesView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showAdNetworkView) {
            AdNetworkView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showTargetingView) {
            TargetingView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showAppsView) {
            AppsView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                .environmentObject(authViewModel)
        }
    }
    
    private func initializeAsync() async {
        // Small delay to ensure view hierarchy is loaded
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        await MainActor.run {
            // Ensure settingsViewModel has the correct authViewModel reference
            settingsViewModel.authViewModel = authViewModel
            
            // Mark as initialized
            isInitialized = true
        }
    }
}

// MARK: - Modern Tab Bar
struct ModernTabBar: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) private var colorScheme
    @State private var tabIndicatorOffset: CGFloat = 0
    @State private var animationAmount: CGFloat = 1.0
    
    private let tabItems: [(icon: String, activeIcon: String, title: String, color: Color)] = [
        ("rectangle.3.group", "rectangle.3.group.fill", "Overview", .blue),
        ("chart.line.uptrend.xyaxis", "chart.line.uptrend.xyaxis", "Trends", .orange),
        ("creditcard", "creditcard.fill", "Payments", .green),
        ("gearshape", "gearshape.fill", "Settings", .purple)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab bar content
            HStack(spacing: 0) {
                ForEach(0..<tabItems.count, id: \.self) { index in
                    ModernTabItem(
                        icon: tabItems[index].icon,
                        activeIcon: tabItems[index].activeIcon,
                        title: tabItems[index].title,
                        color: tabItems[index].color,
                        isSelected: selectedTab == index
                    ) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            selectedTab = index
                            
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(
                // Glassmorphism background
                ZStack {
                    // Base background
                    Color(.systemBackground)
                        .opacity(colorScheme == .dark ? 0.9 : 0.95)
                    
                    // Subtle gradient overlay
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(.systemBackground).opacity(0.1), location: 0),
                            .init(color: Color(.systemBackground).opacity(0.05), location: 1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .background(.ultraThinMaterial)
                .ignoresSafeArea(.container, edges: .bottom)
            )
            .overlay(
                // Top border
                Rectangle()
                    .fill(Color(.separator).opacity(0.3))
                    .frame(height: 0.5),
                alignment: .top
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.1 : 0.03),
                radius: 12,
                x: 0,
                y: -3
            )
            .safeAreaInset(edge: .bottom) {
                // Add safe area padding at the bottom
                Color.clear
                    .frame(height: 0)
            }
        }
    }
}

// MARK: - Modern Tab Item
struct ModernTabItem: View {
    let icon: String
    let activeIcon: String
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var bounceAnimation = false
    
    var body: some View {
        Button(action: {
            action()
            
            // Bounce animation for icon
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                bounceAnimation = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                bounceAnimation = false
            }
        }) {
            VStack(spacing: 6) {
                // Icon container with background
                ZStack {
                    // Background circle for selected state
                    Circle()
                        .fill(
                            isSelected 
                            ? LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: color.opacity(0.2), location: 0),
                                    .init(color: color.opacity(0.1), location: 0.6),
                                    .init(color: color.opacity(0.05), location: 1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                gradient: Gradient(colors: [Color.clear]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: isSelected ? 44 : 0, height: isSelected ? 44 : 0)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? color.opacity(0.2) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
                    
                    // Icon
                    Image(systemName: isSelected ? activeIcon : icon)
                        .font(.system(size: 22, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? color : .secondary)
                        .scaleEffect(
                            bounceAnimation ? 1.2 : (isPressed ? 0.9 : 1.0)
                        )
                        .rotationEffect(.degrees(bounceAnimation ? 5 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                        .animation(.spring(response: 0.3, dampingFraction: 0.4), value: bounceAnimation)
                        .animation(.easeInOut(duration: 0.15), value: isPressed)
                }
                .frame(height: 44)
                
                // Title
                Text(title)
                    .soraCaption()
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? color : .secondary)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            action()
        }
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
    }
}

// MARK: - Press Events Extension
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    onPress()
                }
                .onEnded { _ in
                    onRelease()
                }
        )
    }
}

#Preview {
    SummaryTabView()
        .environmentObject(AuthViewModel())
} 
