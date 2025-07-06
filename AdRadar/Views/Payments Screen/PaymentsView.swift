import SwiftUI
import UIKit

struct PaymentsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @StateObject private var viewModel: PaymentsViewModel
    @Environment(\.colorScheme) private var uiColorScheme
    @State private var unpaidCardAppeared = false
    @State private var previousCardAppeared = false
    @State private var animateFloatingElements = false
    @Binding var showSlideOverMenu: Bool
    @Binding var selectedTab: Int
    
    private var formattedLastUpdateTime: String {
        guard let lastUpdateTime = viewModel.lastUpdateTime else {
            return "never"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdateTime, relativeTo: Date())
    }
    
    init(showSlideOverMenu: Binding<Bool>, selectedTab: Binding<Int>) {
        _viewModel = StateObject(wrappedValue: PaymentsViewModel(accessToken: nil))
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
                PaymentsFloatingElementsView(animate: $animateFloatingElements)
                
                ScrollView {
                    VStack(spacing: 16) {
                        if viewModel.isLoading {
                            Spacer()
                            ProgressView("Loading payments...")
                                .soraBody()
                                .padding()
                            Spacer()
                        } else if viewModel.showEmptyState {
                            PaymentsEmptyStateView(message: viewModel.emptyStateMessage)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 100)
                        } else if let error = viewModel.error {
                            Spacer()
                            ErrorBannerView(message: error, symbol: errorSymbol(for: error))
                            Spacer()
                        } else if let data = viewModel.paymentsData {
                            VStack(alignment: .leading, spacing: 12) {
                                // Last Updated Header
                                PaymentsHeaderView(lastUpdateTime: formattedLastUpdateTime)
                                
                                // Payment threshold progress
                                PaymentProgressView(
                                    currentMonthEarnings: data.currentMonthEarningsValue,
                                    paymentThreshold: settingsViewModel.currentPaymentThreshold
                                )
                                .opacity(unpaidCardAppeared ? 1 : 0)
                                .offset(y: unpaidCardAppeared ? 0 : 20)
                                
                                UnpaidEarningsCardView(
                                    amount: data.unpaidEarnings,
                                    unpaidValue: data.unpaidEarningsValue,
                                    paymentThreshold: settingsViewModel.currentPaymentThreshold,
                                    date: data.previousPaymentDate,
                                    isPaid: false
                                )
                                .opacity(unpaidCardAppeared ? 1 : 0)
                                .offset(y: unpaidCardAppeared ? 0 : 20)
                                
                                PreviousPaymentCardView(
                                    amount: data.previousPaymentAmount,
                                    date: data.previousPaymentDate
                                )
                                .opacity(previousCardAppeared ? 1 : 0)
                                .offset(y: previousCardAppeared ? 0 : 20)
                                .onAppear {
                                    // Animate unpaid card first
                                    withAnimation(.easeOut(duration: 0.5)) {
                                        unpaidCardAppeared = true
                                    }
                                    
                                    // Animate previous payment card after delay
                                    withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                                        previousCardAppeared = true
                                    }
                                }
                                .onDisappear {
                                    // Reset animation states when view disappears
                                    unpaidCardAppeared = false
                                    previousCardAppeared = false
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                            Text("AdRadar is not affiliated with Google or Google AdSense.")
                                .soraFootnote()
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                        }
                    }
                    .padding(.top)
                }
            }
            .refreshable {
                if let token = authViewModel.accessToken {
                    viewModel.accessToken = token
                    viewModel.authViewModel = authViewModel
                    await viewModel.fetchPayments()
                }
            }
            .onAppear {
                // Only fetch data on first load, not on every tab switch
                if let token = authViewModel.accessToken, !viewModel.hasLoaded {
                    viewModel.accessToken = token
                    viewModel.authViewModel = authViewModel
                    Task { await viewModel.fetchPayments() }
                }
                
                // Animate floating elements
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                    animateFloatingElements = true
                }
            }
            .navigationTitle("Payments")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSlideOverMenu = true
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
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
    }
    
    // Helper to pick an SF Symbol for the error
    private func errorSymbol(for error: String) -> String {
        if error.localizedCaseInsensitiveContains("internet") || error.localizedCaseInsensitiveContains("offline") {
            return "wifi.slash"
        } else if error.localizedCaseInsensitiveContains("unauthorized") || error.localizedCaseInsensitiveContains("session") {
            return "person.crop.circle.badge.exclamationmark"
        } else {
            return "exclamationmark.triangle"
        }
    }
} 
