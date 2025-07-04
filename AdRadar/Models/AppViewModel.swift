import Foundation
import SwiftUI

@MainActor
class AppViewModel: ObservableObject {
    @Published var apps: [AppData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter: DateFilter = .last7Days
    @Published var hasLoaded = false
    @Published var showEmptyState: Bool = false
    @Published var emptyStateMessage: String? = nil
    
    var accessToken: String?
    var authViewModel: AuthViewModel?
    var admobAccountID: String?
    
    init(accessToken: String?) {
        self.accessToken = accessToken
    }
    
    func fetchAppData() async {
        guard let accessToken = accessToken else {
            errorMessage = "No access token available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        showEmptyState = false
        emptyStateMessage = nil
        
        // If in demo mode, use demo data
        if let authVM = authViewModel, authVM.isDemoMode {
            // Create demo app data
            let dateRange = selectedFilter.dateRange
            let daysBetween = Calendar.current.dateComponents([.day], from: dateRange.start, to: dateRange.end).day ?? 1
            let multiplier = Double(daysBetween) / 7.0  // Scale data based on date range
            
            // Helper function to scale numeric values
            func scaleValue(_ value: Double) -> String {
                return String(format: "%.2f", value * multiplier)
            }
            
            let demoApps = [
                AppData(
                    appName: "Demo Game",
                    appId: "com.example.demogame",
                    earnings: scaleValue(245.67),
                    impressions: scaleValue(25000),
                    clicks: scaleValue(856),
                    ctr: "3.35",
                    rpm: "14.60",
                    requests: scaleValue(28000)
                ),
                AppData(
                    appName: "Demo Utility",
                    appId: "com.example.demoutility",
                    earnings: scaleValue(156.45),
                    impressions: scaleValue(15000),
                    clicks: scaleValue(634),
                    ctr: "3.34",
                    rpm: "14.50",
                    requests: scaleValue(16800)
                )
            ]
            
            self.apps = demoApps
            self.isLoading = false
            self.errorMessage = nil
            self.hasLoaded = true
            self.showEmptyState = false
            return
        }
        
        // First, get the AdMob account ID if we don't have it
        if admobAccountID == nil {
            let accountResult = await AdMobAPI.fetchAccountID(accessToken: accessToken)
            switch accountResult {
            case .success(let accountID):
                admobAccountID = accountID
                print("AdMob Account ID: \(accountID)")
            case .failure(let error):
                await handleError(error)
                return
            }
        }
        
        guard let accountID = admobAccountID else {
            errorMessage = "Failed to get AdMob account ID"
            isLoading = false
            return
        }
        
        // Fetch apps data for the selected date range
        let dateRange = selectedFilter.dateRange
        let result = await fetchAppsData(accountID: accountID, accessToken: accessToken, startDate: dateRange.start, endDate: dateRange.end)
        
        switch result {
        case .success(let appsData):
            apps = appsData
            hasLoaded = true
        case .failure(let error):
            await handleError(error)
        }
        
        isLoading = false
    }
    
    private func fetchAppsData(accountID: String, accessToken: String, startDate: Date, endDate: Date) async -> Result<[AppData], AdMobError> {
        guard NetworkMonitor.shared.shouldProceedWithRequest() else {
            return .failure(.requestFailed("No internet connection"))
        }
        
        print("Fetching AdMob apps data for account: \(accountID)")
        print("Date range: \(startDate) to \(endDate)")
        
        let result = await AdMobAPI.shared.fetchAppsReport(accountID: accountID, accessToken: accessToken, startDate: startDate, endDate: endDate)
        
        switch result {
        case .success(let reportResponse):
            print("AdMob API Response received")
            
            // Parse the response into AppData objects
            var appsData: [AppData] = []
            
            if let rows = reportResponse.row {
                print("Processing \(rows.count) rows from AdMob response")
                
                for row in rows {
                    if let appData = AppData.fromAdMobResponse(row) {
                        appsData.append(appData)
                        print("Added app: \(appData.appName) with earnings: \(appData.earnings)")
                    }
                }
            } else {
                print("No rows found in AdMob response")
            }
            
            // Sort by earnings (highest first)
            appsData.sort { (lhs, rhs) in
                let leftEarnings = Double(lhs.earnings) ?? 0.0
                let rightEarnings = Double(rhs.earnings) ?? 0.0
                return leftEarnings > rightEarnings
            }
            
            print("Returning \(appsData.count) apps")
            return .success(appsData)
            
        case .failure(let error):
            print("AdMob API Error: \(error)")
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
                    // Retry the request
                    await fetchAppData()
                    return
                } else {
                    showEmptyState = true
                    emptyStateMessage = "Please sign in again to access your AdMob data."
                    errorMessage = nil
                }
            } else {
                showEmptyState = true
                emptyStateMessage = "Please sign in again to access your AdMob data."
                errorMessage = nil
            }
        case .requestFailed(let message):
            // Check for specific UNAUTHENTICATED status
            if message.contains("UNAUTHENTICATED|") {
                showEmptyState = true
                // Show specific message for missing AdMob account
                emptyStateMessage = "NO_ADMOB_ACCOUNT"
                errorMessage = nil
            }
            // Check if this is a scope issue
            else if message.contains("insufficient authentication scopes") || message.contains("Access forbidden") {
                errorMessage = "AdMob access requires additional permissions. Please grant AdMob access in your Google account settings or contact support."
            } else {
                errorMessage = message
            }
        case .noAccountID:
            errorMessage = "No AdMob account found. Please make sure you have an active AdMob account."
        case .invalidURL:
            errorMessage = "Invalid request URL"
        case .invalidResponse:
            errorMessage = "Invalid response from AdMob API"
        case .decodingError(let message):
            errorMessage = "Data parsing error: \(message)"
        case .noData:
            errorMessage = "No app data available for the selected period"
        }
    }
} 