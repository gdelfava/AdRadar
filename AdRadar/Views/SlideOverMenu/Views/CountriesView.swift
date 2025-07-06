import SwiftUI

struct CountriesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: CountryViewModel
    @State private var showingDateFilter = false
    @State private var showTotalEarningsCard = false
    @Binding var showSlideOverMenu: Bool
    @Binding var selectedTab: Int
    @Environment(\.dismiss) private var dismiss
    
    init(showSlideOverMenu: Binding<Bool>, selectedTab: Binding<Int>) {
        _showSlideOverMenu = showSlideOverMenu
        _selectedTab = selectedTab
        _viewModel = StateObject(wrappedValue: CountryViewModel(accessToken: nil))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                mainContent
            }
            .navigationTitle("Countries")
            .toolbar {
                leadingToolbarItem
                trailingToolbarItem
            }
        }
        .sheet(isPresented: $showingDateFilter) {
            DateFilterSheet(selectedFilter: $viewModel.selectedFilter, isPresented: $showingDateFilter) {
                // Reset total earnings card when filter changes
                showTotalEarningsCard = false
                Task {
                    await viewModel.fetchCountryData()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            filterButton
        }
        .onAppear {
            if let token = authViewModel.accessToken, !viewModel.hasLoaded {
                viewModel.accessToken = token
                viewModel.authViewModel = authViewModel
                Task { await viewModel.fetchCountryData() }
            }
            
            // Reset total earnings card visibility
            showTotalEarningsCard = false
        }
        .onChange(of: viewModel.countries) { oldCountries, newCountries in
            // Show total earnings card after countries have loaded
            if !newCountries.isEmpty && viewModel.hasLoaded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showTotalEarningsCard = true
                }
            } else {
                showTotalEarningsCard = false
            }
        }
        .onChange(of: viewModel.hasLoaded) { oldValue, newValue in
            // Reset total earnings card when loading state changes
            if newValue && !viewModel.countries.isEmpty {
                showTotalEarningsCard = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showTotalEarningsCard = true
                }
            } else {
                showTotalEarningsCard = false
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var mainContent: some View {
        Group {
            if let error = viewModel.error {
                ErrorBannerView(message: error, symbol: errorSymbol(for: error))
                    .padding(.horizontal)
                    .padding(.top)
            }
            
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading countries...")
                    .soraBody()
                    .padding()
                Spacer()
            } else if viewModel.showEmptyState {
                emptyStateView
            } else {
                countriesScrollView
            }
        }
    }
    
    private var emptyStateView: some View {
        CountriesEmptyStateView(message: viewModel.emptyStateMessage ?? "No country data available for the selected time period. Try a different date range or ensure your ads are running.")
            .padding(.horizontal, 20)
            .padding(.vertical, 100)
    }
    
    private var countriesScrollView: some View {
        ScrollView {
            VStack(spacing: 16) {
                totalEarningsCard
                countryCardsList
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 100)
        }
        .refreshable {
            if let token = authViewModel.accessToken {
                viewModel.accessToken = token
                viewModel.authViewModel = authViewModel
                await viewModel.fetchCountryData()
            }
        }
    }
    
    private var totalEarningsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Total Earnings")
                    .soraHeadline()
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(calculateTotalEarnings())
                    .soraLargeTitle()
                    .foregroundColor(.accentColor)
            }
            
            HStack {
                Image(systemName: "flag")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(viewModel.countries.count) countr\(viewModel.countries.count == 1 ? "y" : "ies")")
                    .soraCaption()
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Period: \(viewModel.selectedFilter.rawValue)")
                    .soraCaption()
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .opacity(showTotalEarningsCard ? 1 : 0)
        .offset(y: showTotalEarningsCard ? 0 : 20)
        .animation(.easeOut(duration: 0.4), value: showTotalEarningsCard)
    }
    
    private var countryCardsList: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(viewModel.countries.enumerated()), id: \.element.id) { index, country in
                CountryCard(country: country)
            }
        }
    }
    
    private var leadingToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Done") {
                dismiss()
            }
            .soraBody()
            .foregroundColor(.accentColor)
        }
    }
    
    private var trailingToolbarItem: some ToolbarContent {
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
    
    private var filterButton: some View {
        Button(action: {
            showingDateFilter = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.body)
                    .foregroundColor(.white)
                Text(viewModel.selectedFilter.rawValue)
                    .soraBody()
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Helper Methods
    
    private func calculateTotalEarnings() -> String {
        let total = viewModel.countries.reduce(0.0) { sum, country in
            sum + (Double(country.earnings) ?? 0)
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        if authViewModel.isDemoMode {
            formatter.currencySymbol = "$"
        } else {
            formatter.locale = Locale.current
        }
        return formatter.string(from: NSNumber(value: total)) ?? "$0.00"
    }
    
    private func errorSymbol(for error: String) -> String {
        if error.contains("internet") || error.contains("connection") {
            return "wifi.slash"
        } else if error.contains("unauthorized") || error.contains("forbidden") {
            return "lock.fill"
        } else if error.contains("timeout") {
            return "clock"
        } else {
            return "exclamationmark.triangle"
        }
    }
}

// MARK: - Countries Empty State View

struct CountriesEmptyStateView: View {
    let message: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            // Enhanced icon with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.orange.opacity(0.15),
                                Color.orange.opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "flag.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.orange)
            }
            
            // Enhanced content
            VStack(spacing: 12) {
                Text("No Country Data Available")
                    .soraHeadline()
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                Text("No country data available for the selected time period. Try a different date range or ensure your ads are running.")
                    .soraCaption()
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                // Base gradient background
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.orange.opacity(0.08), location: 0),
                        .init(color: Color.orange.opacity(0.04), location: 0.5),
                        .init(color: Color.orange.opacity(0.02), location: 1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Pattern overlay for visual interest
                PatternOverlay(color: .orange.opacity(0.03))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.orange.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 16, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.orange.opacity(0.2),
                            Color.clear,
                            Color.orange.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
} 