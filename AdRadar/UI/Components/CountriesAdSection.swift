import SwiftUI

struct CountriesAdSection: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var countryViewModel: CountryAdViewModel
    let appData: AppData
    let accountID: String
    let dateRange: (start: Date, end: Date)
    
    init(appData: AppData, accountID: String, dateRange: (start: Date, end: Date)) {
        self.appData = appData
        self.accountID = accountID
        self.dateRange = dateRange
        self._countryViewModel = StateObject(wrappedValue: CountryAdViewModel(accessToken: nil))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text("Countries")
                    .soraTitle2()
                    .foregroundColor(.primary)
                
                Spacer()
                
                if countryViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 20)
            
            // Filter Section
            CountryAdFilterView(selectedFilter: $countryViewModel.selectedFilter) { filter in
                countryViewModel.setFilter(filter)
            }
            
            // Content Section
            if let errorMessage = countryViewModel.errorMessage {
                errorView(errorMessage)
            } else if countryViewModel.filteredCountries.isEmpty && !countryViewModel.isLoading {
                emptyStateView
            } else {
                countriesListView
            }
        }
        .onAppear {
            setupViewModel()
            Task {
                await countryViewModel.fetchCountriesData(
                    for: appData.appId,
                    accountID: accountID,
                    dateRange: dateRange
                )
            }
        }
        .onChange(of: authViewModel.accessToken) { oldToken, newToken in
            if let token = newToken {
                countryViewModel.accessToken = token
                Task {
                    await countryViewModel.fetchCountriesData(
                        for: appData.appId,
                        accountID: accountID,
                        dateRange: dateRange
                    )
                }
            }
        }
    }
    
    private func setupViewModel() {
        countryViewModel.accessToken = authViewModel.accessToken
        countryViewModel.authViewModel = authViewModel
    }
    
    private var countriesListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(countryViewModel.filteredCountries) { country in
                CountryAdCard(
                    country: country,
                    selectedFilter: countryViewModel.selectedFilter
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "globe.badge.chevron.backward")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            
            Text("No Country Data")
                .soraSubheadline()
                .foregroundColor(.secondary)
            
            Text("No country performance data available for this app and date range.")
                .soraCaption()
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundColor(.orange)
            
            Text("Error Loading Countries")
                .soraSubheadline()
                .foregroundColor(.secondary)
            
            Text(message)
                .soraCaption()
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await countryViewModel.fetchCountriesData(
                        for: appData.appId,
                        accountID: accountID,
                        dateRange: dateRange
                    )
                }
            }
            .soraCaption()
            .foregroundColor(.accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
    }
} 