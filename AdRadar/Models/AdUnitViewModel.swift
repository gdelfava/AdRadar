import Foundation
import SwiftUI

@MainActor
class AdUnitViewModel: ObservableObject {
    @Published var adUnits: [AdUnitData] = []
    @Published var filteredAdUnits: [AdUnitData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter: AdUnitMetricFilter = .earnings
    @Published var hasLoaded = false
    
    var accessToken: String?
    var authViewModel: AuthViewModel?
    var currentAppId: String?
    var currentDateRange: (start: Date, end: Date)?
    
    private var admobAccountID: String?
    
    init(accessToken: String?) {
        self.accessToken = accessToken
    }
    
    func fetchAdUnitsData(for appId: String, accountID: String, dateRange: (start: Date, end: Date)) async {
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
            createDemoAdUnitsData()
            return
        }
        
        // Fetch ad units data for the specific app
        let result = await fetchAdUnitsDataFromAPI(accountID: accountID, appId: appId, accessToken: accessToken, startDate: dateRange.start, endDate: dateRange.end)
        
        switch result {
        case .success(let adUnitsData):
            adUnits = adUnitsData
            applyFilter()
            hasLoaded = true
        case .failure(let error):
            await handleError(error)
        }
        
        isLoading = false
    }
    
    func setFilter(_ filter: AdUnitMetricFilter) {
        selectedFilter = filter
        applyFilter()
    }
    
    private func applyFilter() {
        // Sort ad units based on selected filter
        let sortedAdUnits = adUnits.sorted { (lhs, rhs) in
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
        
        filteredAdUnits = sortedAdUnits
    }
    
    private func createDemoAdUnitsData() {
        // Create static demo ad units data with $ currency symbols
        let demoAdUnits = [
            AdUnitData(
                adUnitName: "Banner Ad",
                adUnitId: "ca-app-pub-1234567890123456/1234567890",
                adUnitFormat: "Banner",
                adType: "Banner",
                earnings: "12.45",
                impressions: "8500",
                clicks: "85",
                ctr: "1.0",
                eCPM: "1.46",
                requests: "9200"
            ),
            AdUnitData(
                adUnitName: "Interstitial Ad",
                adUnitId: "ca-app-pub-1234567890123456/0987654321",
                adUnitFormat: "Interstitial",
                adType: "Interstitial",
                earnings: "28.90",
                impressions: "1250",
                clicks: "62",
                ctr: "4.96",
                eCPM: "23.12",
                requests: "1380"
            ),
            AdUnitData(
                adUnitName: "Rewarded Video",
                adUnitId: "ca-app-pub-1234567890123456/5678901234",
                adUnitFormat: "Rewarded",
                adType: "Video",
                earnings: "45.67",
                impressions: "920",
                clicks: "138",
                ctr: "15.0",
                eCPM: "49.64",
                requests: "1050"
            ),
            AdUnitData(
                adUnitName: "Native Ad",
                adUnitId: "ca-app-pub-1234567890123456/4567890123",
                adUnitFormat: "Native",
                adType: "Native",
                earnings: "18.23",
                impressions: "3400",
                clicks: "102",
                ctr: "3.0",
                eCPM: "5.36",
                requests: "3650"
            )
        ]
        
        self.adUnits = demoAdUnits
        applyFilter()
        self.isLoading = false
        self.errorMessage = nil
        self.hasLoaded = true
    }
    
    private func fetchAdUnitsDataFromAPI(accountID: String, appId: String, accessToken: String, startDate: Date, endDate: Date) async -> Result<[AdUnitData], AdMobError> {
        guard NetworkMonitor.shared.shouldProceedWithRequest() else {
            return .failure(.requestFailed("No internet connection"))
        }
        
        print("Fetching AdMob ad units data for app: \(appId)")
        print("Date range: \(startDate) to \(endDate)")
        
        let result = await AdMobAPI.shared.fetchAdUnitsReport(accountID: accountID, appId: appId, accessToken: accessToken, startDate: startDate, endDate: endDate)
        
        switch result {
        case .success(let reportResponse):
            print("AdMob Ad Units API Response received")
            
            // Parse the response into AdUnitData objects
            var adUnitsData: [AdUnitData] = []
            
            if let rows = reportResponse.row {
                print("Processing \(rows.count) rows from AdMob ad units response")
                
                for row in rows {
                    if let adUnitData = AdUnitData.fromAdMobResponse(row) {
                        adUnitsData.append(adUnitData)
                        print("Added ad unit: \(adUnitData.adUnitName) with earnings: \(adUnitData.earnings)")
                    }
                }
            } else {
                print("No rows found in AdMob ad units response")
            }
            
            print("Returning \(adUnitsData.count) ad units")
            return .success(adUnitsData)
            
        case .failure(let error):
            print("AdMob Ad Units API Error: \(error)")
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
                        await fetchAdUnitsData(for: appId, accountID: accountID, dateRange: dateRange)
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
            errorMessage = "No ad unit data available for the selected period"
        }
    }
} 