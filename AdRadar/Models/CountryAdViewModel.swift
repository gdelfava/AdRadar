import Foundation
import SwiftUI

@MainActor
class CountryAdViewModel: ObservableObject {
    @Published var countries: [CountryAdData] = []
    @Published var filteredCountries: [CountryAdData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter: CountryAdMetricFilter = .earnings
    @Published var hasLoaded = false
    
    var accessToken: String?
    var authViewModel: AuthViewModel?
    var currentAppId: String?
    var currentDateRange: (start: Date, end: Date)?
    
    private var admobAccountID: String?
    
    init(accessToken: String?) {
        self.accessToken = accessToken
    }
    
    func fetchCountriesData(for appId: String, accountID: String, dateRange: (start: Date, end: Date)) async {
        guard let accessToken = accessToken else {
            errorMessage = "No access token available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        currentAppId = appId
        currentDateRange = dateRange
        admobAccountID = accountID
        
        // If in demo mode, use demo data
        if let authVM = authViewModel, authVM.isDemoMode {
            createDemoCountriesData()
            return
        }
        
        // Fetch countries data for the specific app
        let result = await fetchCountriesDataFromAPI(accountID: accountID, appId: appId, accessToken: accessToken, startDate: dateRange.start, endDate: dateRange.end)
        
        switch result {
        case .success(let countriesData):
            countries = countriesData
            applyFilter()
            hasLoaded = true
        case .failure(let error):
            await handleError(error)
        }
        
        isLoading = false
    }
    
    func setFilter(_ filter: CountryAdMetricFilter) {
        selectedFilter = filter
        applyFilter()
    }
    
    private func applyFilter() {
        // Sort countries based on selected filter
        let sortedCountries = countries.sorted { (lhs, rhs) in
            switch selectedFilter {
            case .earnings:
                let leftValue = Double(lhs.earnings) ?? 0.0
                let rightValue = Double(rhs.earnings) ?? 0.0
                return leftValue > rightValue
            case .clicks:
                let leftValue = Double(lhs.clicks) ?? 0.0
                let rightValue = Double(rhs.clicks) ?? 0.0
                return leftValue > rightValue
            case .impressions:
                let leftValue = Double(lhs.impressions) ?? 0.0
                let rightValue = Double(rhs.impressions) ?? 0.0
                return leftValue > rightValue
            case .requests:
                let leftValue = Double(lhs.requests) ?? 0.0
                let rightValue = Double(rhs.requests) ?? 0.0
                return leftValue > rightValue
            case .eCPM:
                let leftValue = Double(lhs.eCPM) ?? 0.0
                let rightValue = Double(rhs.eCPM) ?? 0.0
                return leftValue > rightValue
            }
        }
        
        filteredCountries = sortedCountries
    }
    
    private func createDemoCountriesData() {
        // Create static demo countries data with $ currency symbols
        let demoCountries = [
            CountryAdData(
                countryName: "United States",
                countryCode: "US",
                earnings: "24.67",
                impressions: "12000",
                clicks: "120",
                ctr: "1.0",
                eCPM: "2.06",
                requests: "13200"
            ),
            CountryAdData(
                countryName: "United Kingdom",
                countryCode: "GB",
                earnings: "18.45",
                impressions: "9500",
                clicks: "95",
                ctr: "1.0",
                eCPM: "1.94",
                requests: "10450"
            ),
            CountryAdData(
                countryName: "Canada",
                countryCode: "CA",
                earnings: "15.23",
                impressions: "8200",
                clicks: "82",
                ctr: "1.0",
                eCPM: "1.86",
                requests: "9020"
            ),
            CountryAdData(
                countryName: "Australia",
                countryCode: "AU",
                earnings: "12.89",
                impressions: "6800",
                clicks: "68",
                ctr: "1.0",
                eCPM: "1.90",
                requests: "7480"
            ),
            CountryAdData(
                countryName: "Germany",
                countryCode: "DE",
                earnings: "8.34",
                impressions: "4500",
                clicks: "45",
                ctr: "1.0",
                eCPM: "1.85",
                requests: "4950"
            ),
            CountryAdData(
                countryName: "Japan",
                countryCode: "JP",
                earnings: "6.78",
                impressions: "3600",
                clicks: "36",
                ctr: "1.0",
                eCPM: "1.88",
                requests: "3960"
            )
        ]
        
        self.countries = demoCountries
        applyFilter()
        self.isLoading = false
        self.errorMessage = nil
        self.hasLoaded = true
    }
    
    private func fetchCountriesDataFromAPI(accountID: String, appId: String, accessToken: String, startDate: Date, endDate: Date) async -> Result<[CountryAdData], AdMobError> {
        guard NetworkMonitor.shared.shouldProceedWithRequest() else {
            return .failure(.requestFailed("No internet connection"))
        }
        
        print("Fetching AdMob countries data for app: \(appId)")
        print("Date range: \(startDate) to \(endDate)")
        
        let result = await AdMobAPI.shared.fetchCountriesReport(accountID: accountID, appId: appId, accessToken: accessToken, startDate: startDate, endDate: endDate)
        
        switch result {
        case .success(let reportResponse):
            print("AdMob Countries API Response received")
            
            // Parse the response into CountryAdData objects
            var countriesData: [CountryAdData] = []
            
            if let rows = reportResponse.row {
                print("Processing \(rows.count) rows from AdMob countries response")
                
                for row in rows {
                    if let countryData = CountryAdData.fromAdMobResponse(row) {
                        countriesData.append(countryData)
                        print("Added country: \(countryData.countryName) with earnings: \(countryData.earnings)")
                    }
                }
            } else {
                print("No rows found in AdMob countries response")
            }
            
            print("Returning \(countriesData.count) countries")
            return .success(countriesData)
            
        case .failure(let error):
            print("AdMob Countries API Error: \(error)")
            return .failure(error)
        }
    }
    
    private func handleError(_ error: AdMobError) async {
        switch error {
        case .unauthorized:
            // Token might be expired, try to refresh
            if let authViewModel = authViewModel {
                let refreshSuccess = await authViewModel.refreshTokenIfNeeded()
                if refreshSuccess, let newToken = authViewModel.accessToken {
                    self.accessToken = newToken
                    // Retry the request if we have the necessary data
                    if let appId = currentAppId,
                       let accountID = admobAccountID,
                       let dateRange = currentDateRange {
                        await fetchCountriesData(for: appId, accountID: accountID, dateRange: dateRange)
                    }
                    return
                } else {
                    errorMessage = "Please sign in again to access your AdMob data."
                }
            } else {
                errorMessage = "Please sign in again to access your AdMob data."
            }
        case .requestFailed(let message):
            errorMessage = message
        case .noAccountID:
            errorMessage = "No AdMob account found. Please make sure you have an active AdMob account."
        case .invalidURL:
            errorMessage = "Invalid request URL"
        case .invalidResponse:
            errorMessage = "Invalid response from AdMob API"
        case .decodingError(let message):
            errorMessage = "Data parsing error: \(message)"
        case .noData:
            errorMessage = "No country data available for the selected period"
        }
    }
} 