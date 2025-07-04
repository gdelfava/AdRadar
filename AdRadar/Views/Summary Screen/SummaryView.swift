import SwiftUI
import UIKit
import Combine
import GoogleSignIn

/// The main summary view that displays various performance metrics in a scrollable layout.
/// Features animated cards, sections, and error handling.
struct SummaryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: SummaryViewModel
    @State private var cardAppearances: [Bool] = Array(repeating: false, count: 6)
    @State private var animateFloatingElements = false
    @Binding var showSlideOverMenu: Bool
    @Binding var selectedTab: Int
    
    init(showSlideOverMenu: Binding<Bool>, selectedTab: Binding<Int>) {
        _viewModel = StateObject(wrappedValue: SummaryViewModel(accessToken: nil))
        _showSlideOverMenu = showSlideOverMenu
        _selectedTab = selectedTab
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background - always full screen
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color.accentColor.opacity(0.1),
                        Color(.systemBackground)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                // Floating elements for visual interest
                SummaryFloatingElementsView(animate: $animateFloatingElements)
                
                ScrollView {
                    VStack(alignment: .center, spacing: 0) {
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .soraBody()
                                .foregroundColor(.red)
                                .padding()
                        }
                        if viewModel.isOffline {
                            Text("No internet connection. Please check your network and try again.")
                                .soraBody()
                                .foregroundColor(.red)
                                .padding()
                        }

                        if viewModel.isLoading {
                            Spacer()
                            ProgressView("Loading overview...")
                                .soraBody()
                                .padding()
                            Spacer()
                        } else if let error = viewModel.error {
                            Spacer()
                            ErrorBannerView(message: error, symbol: errorSymbol(for: error))
                            Spacer()
                        } else if let data = viewModel.summaryData {
                            LazyVStack(spacing: 24) {
                                // HERO SECTION - Today's performance
                                VStack(spacing: 16) {
                                    HeroSectionHeader(lastUpdateTime: viewModel.lastUpdateTime)
                                        .padding(.horizontal, 20)
                                    
                                    HeroSummaryCard(
                                        title: "Today So Far",
                                        value: data.today,
                                        subtitle: "vs yesterday",
                                        delta: data.todayDelta,
                                        deltaPositive: data.todayDeltaPositive,
                                        onTap: { Task { await viewModel.fetchMetrics(forCard: .today) } }
                                    )
                                    .opacity(cardAppearances[0] ? 1 : 0)
                                    .offset(y: cardAppearances[0] ? 0 : 30)
                                    .padding(.horizontal, 16)
                                }
                                .padding(.top, 8)
                                
                                // RECENT SECTION - Yesterday & Last 7 Days
                                VStack(spacing: 16) {
                                    SectionHeader(title: "Recent Performance", icon: "clock.fill", color: .orange)
                                    
                                    VStack(spacing: 12) {
                                        CompactSummaryCard(
                                            title: "Yesterday",
                                            value: data.yesterday,
                                            subtitle: "vs the same day last week",
                                            delta: data.yesterdayDelta,
                                            deltaPositive: data.yesterdayDeltaPositive,
                                            icon: "calendar.badge.clock",
                                            color: .orange,
                                            onTap: { Task { await viewModel.fetchMetrics(forCard: .yesterday) } }
                                        )
                                        .opacity(cardAppearances[1] ? 1 : 0)
                                        .offset(y: cardAppearances[1] ? 0 : 20)
                                        
                                        CompactSummaryCard(
                                            title: "Last 7 Days",
                                            value: data.last7Days,
                                            subtitle: "vs the previous 7 days",
                                            delta: data.last7DaysDelta,
                                            deltaPositive: data.last7DaysDeltaPositive,
                                            icon: "calendar.badge.plus",
                                            color: .blue,
                                            onTap: { Task { await viewModel.fetchMetrics(forCard: .last7Days) } }
                                        )
                                        .opacity(cardAppearances[2] ? 1 : 0)
                                        .offset(y: cardAppearances[2] ? 0 : 20)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                // MONTHLY SECTION - This month & Last month
                                VStack(spacing: 16) {
                                    SectionHeader(title: "Monthly Overview", icon: "calendar.circle.fill", color: .purple)
                                    
                                    HStack(spacing: 12) {
                                        MonthlyCompactCard(
                                            title: "This Month",
                                            value: data.thisMonth,
                                            subtitle: "vs same day last month",
                                            delta: data.thisMonthDelta,
                                            deltaPositive: data.thisMonthDeltaPositive,
                                            icon: "calendar",
                                            color: .purple,
                                            onTap: { Task { await viewModel.fetchMetrics(forCard: .thisMonth) } }
                                        )
                                        .opacity(cardAppearances[3] ? 1 : 0)
                                        .offset(y: cardAppearances[3] ? 0 : 20)
                                        
                                        MonthlyCompactCard(
                                            title: "Last Month",
                                            value: data.lastMonth,
                                            subtitle: "vs previous month",
                                            delta: data.lastMonthDelta,
                                            deltaPositive: data.lastMonthDeltaPositive,
                                            icon: "calendar.badge.minus",
                                            color: .pink,
                                            onTap: { Task { await viewModel.fetchMetrics(forCard: .lastMonth) } }
                                        )
                                        .opacity(cardAppearances[4] ? 1 : 0)
                                        .offset(y: cardAppearances[4] ? 0 : 20)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                // LIFETIME SECTION - All time performance
                                VStack(spacing: 16) {
                                    SectionHeader(title: "All Time", icon: "infinity.circle.fill", color: .indigo)
                                    
                                    LifetimeSummaryCard(
                                        title: "Last Three Years",
                                        value: data.lifetime,
                                        subtitle: "AdRadar for Adsense",
                                        onTap: { Task { await viewModel.fetchMetrics(forCard: .lastThreeYears) } }
                                    )
                                    .opacity(cardAppearances[5] ? 1 : 0)
                                    .offset(y: cardAppearances[5] ? 0 : 20)
                                }
                                .padding(.horizontal, 20)
                            }
                            .onAppear {
                                // Animate cards when they appear
                                for i in 0..<cardAppearances.count {
                                    withAnimation(.easeOut(duration: 0.6).delay(Double(i) * 0.1)) {
                                        cardAppearances[i] = true
                                    }
                                }
                            }
                            .onDisappear {
                                // Reset animation state when view disappears
                                cardAppearances = Array(repeating: false, count: 6)
                            }
                            
                            // Footer
                            VStack(spacing: 12) {
                                Rectangle()
                                    .fill(Color(.separator))
                                    .frame(height: 0.5)
                                    .padding(.horizontal, 20)
                                
                                Text("AdRadar is not affiliated with Google or Google AdSense.")
                                    .soraFootnote()
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 20)
                            }
                            .padding(.top, 32)
                        }
                    }
                    .padding(.top, 20)
                }
            }
            .refreshable {
                if let token = authViewModel.accessToken {
                    await MainActor.run {
                        viewModel.accessToken = token
                        viewModel.authViewModel = authViewModel
                    }
                    await viewModel.fetchSummary()
                }
            }
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSlideOverMenu = true
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileImageView(url: authViewModel.userProfileImageURL)
                        .contextMenu {
                            Button(role: .destructive) {
                                authViewModel.signOut()
                            } label: {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                            Button("Cancel", role: .cancel) { }
                        }
                }
            }
        }
        .onAppear {
            // Defer data fetching to prevent blocking main thread during view loading
            Task {
                // Small delay to ensure view hierarchy is fully loaded
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
                // Only fetch data on first load, not on every tab switch
                if let token = authViewModel.accessToken, !viewModel.hasLoaded {
                    await MainActor.run {
                        viewModel.accessToken = token
                        viewModel.authViewModel = authViewModel
                    }
                    
                    // Fetch summary data asynchronously
                    await viewModel.fetchSummary()
                }
            }
            
            // Animate floating elements independently
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.8)) {
                        animateFloatingElements = true
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .backgroundDataUpdated)) { _ in
            // Refresh UI when background data is updated
            print("[SummaryView] Received background data update notification")
            Task {
                if let token = authViewModel.accessToken {
                    await MainActor.run {
                        viewModel.accessToken = token
                        viewModel.authViewModel = authViewModel
                    }
                    await viewModel.fetchSummary()
                }
            }
        }
        .overlay(
            Group {
                if viewModel.showOfflineToast {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("No internet connection")
                                .soraBody()
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.black.opacity(0.85))
                                .cornerRadius(16)
                            Spacer()
                        }
                        .padding(.bottom, 40)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.showOfflineToast)
                }
            }
        )
        .sheet(isPresented: $viewModel.showNetworkErrorModal) {
            NetworkErrorModalView(
                message: "The Internet connection appears to be offline. Please check your Wi-Fi or Cellular settings.",
                onClose: { viewModel.showNetworkErrorModal = false },
                onSettings: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $viewModel.showDayMetricsSheet) {
            if let metrics = viewModel.selectedDayMetrics {
                DayMetricsSheet(metrics: metrics, title: viewModel.selectedCardTitle)
            } else {
                ProgressView("Loading metrics...")
                    .soraBody()
                    .padding()
            }
        }
    }
    
    // Helper to pick an SF Symbol for the error
    private func errorSymbol(for error: String) -> String {
        if error.localizedCaseInsensitiveContains("internet") || error.localizedCaseInsensitiveContains("offline") {
            return "wifi.slash"
        } else if error.localizedCaseInsensitiveContains("unauthorized") || error.localizedCaseInsensitiveContains("token") {
            return "key.slash"
        } else if error.localizedCaseInsensitiveContains("server") || error.localizedCaseInsensitiveContains("500") {
            return "server.rack"
        } else {
            return "exclamationmark.triangle"
        }
    }
}

#Preview {
    SummaryView(
        showSlideOverMenu: .constant(false),
        selectedTab: .constant(0)
    )
}
