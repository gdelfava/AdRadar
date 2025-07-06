import Foundation
import SwiftUI

@MainActor
class AdSizeViewModel: ObservableObject {
    @Published var adSizes: [AdSizeData] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedFilter: AdSizeDateFilter = .last7Days
    @Published var hasLoaded = false
    @Published var showEmptyState: Bool = false
    @Published var emptyStateMessage: String? = nil
    
    var accessToken: String?
    var authViewModel: AuthViewModel?
    private var accountID: String?
    
    init(accessToken: String?) {
        self.accessToken = accessToken
    }
    
    func fetchAdSizeData() async {
        guard let currentToken = accessToken else {
            self.showEmptyState = true
            self.emptyStateMessage = "Please sign in to view your ad size data"
            self.error = nil
            self.isLoading = false
            return
        }
        
        // Get account ID if not already available
        if accountID == nil {
            let accountResult = await AdSenseAPI.fetchAccountID(accessToken: currentToken)
            switch accountResult {
            case .success(let id):
                self.accountID = id
            case .failure(let error):
                await handleError(error)
                return
            }
        }
        
        guard let accountID = self.accountID else {
            self.showEmptyState = true
            self.emptyStateMessage = "No AdSense account found. Please make sure you have an active AdSense account."
            self.error = nil
            self.isLoading = false
            return
        }
        
        self.isLoading = true
        self.error = nil
        self.showEmptyState = false
        self.emptyStateMessage = nil
        
        let dateRange = selectedFilter.dateRange
        let result = await fetchAdSizesData(
            accountID: accountID,
            accessToken: currentToken,
            startDate: dateRange.start,
            endDate: dateRange.end
        )
        
        switch result {
        case .success(let adSizes):
            self.adSizes = adSizes
            self.hasLoaded = true
            
            // Check if no ad sizes were returned
            if adSizes.isEmpty {
                self.showEmptyState = true
                self.emptyStateMessage = "No ad size data available for the selected time period. Try a different date range or ensure your ads are running."
                self.error = nil
            }
        case .failure(let error):
            await handleError(error)
        }
        
        self.isLoading = false
    }
    
    private func fetchAdSizesData(accountID: String, accessToken: String, startDate: Date, endDate: Date) async -> Result<[AdSizeData], AdSenseError> {
        guard NetworkMonitor.shared.shouldProceedWithRequest() else {
            return .failure(.requestFailed("No internet connection"))
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let start = dateFormatter.string(from: startDate)
        let end = dateFormatter.string(from: endDate)
        
        // Define the metrics and dimensions we want
        let metrics = [
            "ESTIMATED_EARNINGS",
            "AD_REQUESTS",
            "PAGE_VIEWS",
            "IMPRESSIONS",
            "CLICKS",
            "IMPRESSIONS_CTR",
            "IMPRESSIONS_RPM"
        ]
        
        let metricsQuery = metrics.map { "metrics=\($0)" }.joined(separator: "&")
        
        // Try different dimensions in order of preference
        let dimensionsToTry = ["AD_UNIT_NAME", "AD_UNIT_SIZE", "AD_CLIENT"]
        
        for dimension in dimensionsToTry {
            let urlString = "https://adsense.googleapis.com/v2/\(accountID)/reports:generate?\(metricsQuery)&dimensions=\(dimension)&startDate.year=\(start.prefix(4))&startDate.month=\(start.dropFirst(5).prefix(2))&startDate.day=\(start.suffix(2))&endDate.year=\(end.prefix(4))&endDate.month=\(end.dropFirst(5).prefix(2))&endDate.day=\(end.suffix(2))"
            
            print("Trying dimension: \(dimension)")
            
            guard let url = URL(string: urlString) else {
                continue
            }
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 30
            
            do {
                try Task.checkCancellation()
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                try Task.checkCancellation()
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    continue
                }
                
                print("AdSize API Response Status for \(dimension): \(httpResponse.statusCode)")
                
                switch httpResponse.statusCode {
                case 200:
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    guard let rows = json?["rows"] as? [[String: Any]] else {
                        print("No rows found in AdSize API response for \(dimension)")
                        continue
                    }
                    
                    let adSizes = rows.compactMap { row -> AdSizeData? in
                        guard let cells = row["cells"] as? [[String: Any]] else { return nil }
                        
                        // The first cell contains the dimension value
                        let adSize = cells.first?["value"] as? String ?? "Unknown Size"
                        
                        // Initialize default values
                        var earnings = "0"
                        var requests = "0"
                        var pageViews = "0"
                        var impressions = "0"
                        var clicks = "0"
                        var ctr = "0"
                        var rpm = "0"
                        
                        // Map the remaining cells to metrics
                        if cells.count >= 2 {
                            earnings = cells[1]["value"] as? String ?? "0"
                        }
                        if cells.count >= 3 {
                            requests = cells[2]["value"] as? String ?? "0"
                        }
                        if cells.count >= 4 {
                            pageViews = cells[3]["value"] as? String ?? "0"
                        }
                        if cells.count >= 5 {
                            impressions = cells[4]["value"] as? String ?? "0"
                        }
                        if cells.count >= 6 {
                            clicks = cells[5]["value"] as? String ?? "0"
                        }
                        if cells.count >= 7 {
                            ctr = cells[6]["value"] as? String ?? "0"
                        }
                        if cells.count >= 8 {
                            rpm = cells[7]["value"] as? String ?? "0"
                        }
                        
                        return AdSizeData(
                            adSize: adSize,
                            earnings: earnings,
                            requests: requests,
                            pageViews: pageViews,
                            impressions: impressions,
                            clicks: clicks,
                            ctr: ctr,
                            rpm: rpm
                        )
                    }
                    
                    // Sort by earnings (highest first)
                    let sortedAdSizes = adSizes.sorted { 
                        (Double($0.earnings) ?? 0) > (Double($1.earnings) ?? 0)
                    }
                    
                    print("Successfully fetched \(sortedAdSizes.count) ad sizes using dimension: \(dimension)")
                    return .success(sortedAdSizes)
                    
                case 400:
                    print("Dimension \(dimension) not supported, trying next...")
                    continue
                case 401:
                    return .failure(.unauthorized)
                case 403:
                    return .failure(.requestFailed("Access forbidden"))
                default:
                    print("HTTP \(httpResponse.statusCode) for dimension \(dimension), trying next...")
                    continue
                }
            } catch {
                print("Error with dimension \(dimension): \(error)")
                continue
            }
        }
        
        // If we get here, none of the dimensions worked
        return .failure(.requestFailed("No supported dimensions found for ad size data"))
    }
    
    private func handleError(_ error: AdSenseError) async {
        switch error {
        case .unauthorized:
            // Token might be expired, try to refresh
            if let authViewModel = authViewModel {
                let refreshSuccess = await authViewModel.refreshTokenIfNeeded()
                if refreshSuccess, let newToken = authViewModel.accessToken {
                    self.accessToken = newToken
                    // Retry the request
                    await fetchAdSizeData()
                    return
                } else {
                    showEmptyState = true
                    emptyStateMessage = "Please sign in again to access your ad size data."
                    self.error = nil
                }
            } else {
                showEmptyState = true
                emptyStateMessage = "Please sign in again to access your ad size data."
                self.error = nil
            }
        case .requestFailed(let message):
            // Check for specific authentication issues
            if message.contains("insufficient authentication scopes") || message.contains("Access forbidden") {
                showEmptyState = true
                emptyStateMessage = "AdSense access requires additional permissions. Please grant AdSense access in your Google account settings."
                self.error = nil
            } else if message.contains("No internet connection") {
                showEmptyState = true
                emptyStateMessage = "No internet connection. Please check your network and try again."
                self.error = nil
            } else {
                showEmptyState = true
                emptyStateMessage = "Unable to load ad size data. Please try again later."
                self.error = nil
            }
        case .noAccountID:
            showEmptyState = true
            emptyStateMessage = "No AdSense account found. Please make sure you have an active AdSense account."
            self.error = nil
        case .invalidURL:
            showEmptyState = true
            emptyStateMessage = "Unable to load ad size data. Please try again later."
            self.error = nil
        case .invalidResponse:
            showEmptyState = true
            emptyStateMessage = "Unable to load ad size data. Please try again later."
            self.error = nil
        case .decodingError(_):
            showEmptyState = true
            emptyStateMessage = "Unable to load ad size data. Please try again later."
            self.error = nil
        }
    }
} 