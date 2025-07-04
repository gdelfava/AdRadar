import Foundation
import SwiftUI

@MainActor
class PlatformViewModel: ObservableObject {
    @Published var platforms: [PlatformData] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedFilter: PlatformDateFilter = .last7Days
    @Published var hasLoaded = false
    
    var accessToken: String?
    var authViewModel: AuthViewModel?
    private var accountID: String?
    
    init(accessToken: String?) {
        self.accessToken = accessToken
    }
    
    func fetchPlatformData() async {
        guard let currentToken = accessToken else {
            self.error = "No access token available"
            self.isLoading = false
            return
        }
        
        // If in demo mode, use demo data
        if let authVM = authViewModel, authVM.isDemoMode {
            let dateRange = selectedFilter.dateRange
            let mockData = DemoDataProvider.shared.generateMockDataForRange(
                startDate: dateRange.start,
                endDate: dateRange.end
            )
            self.platforms = mockData.platforms
            self.isLoading = false
            self.error = nil
            self.hasLoaded = true
            return
        }
        
        // Get account ID if not already available
        if accountID == nil {
            let accountResult = await AdSenseAPI.fetchAccountID(accessToken: currentToken)
            switch accountResult {
            case .success(let id):
                self.accountID = id
            case .failure(let error):
                self.error = "Failed to get account ID: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
        }
        
        guard let accountID = self.accountID else {
            self.error = "No AdSense account found"
            self.isLoading = false
            return
        }
        
        self.isLoading = true
        self.error = nil
        
        let dateRange = selectedFilter.dateRange
        let result = await fetchPlatformsData(
            accountID: accountID,
            accessToken: currentToken,
            startDate: dateRange.start,
            endDate: dateRange.end
        )
        
        switch result {
        case .success(let platforms):
            self.platforms = platforms
            self.hasLoaded = true
        case .failure(let error):
            self.error = error.localizedDescription
        }
        
        self.isLoading = false
    }
    
    private func fetchPlatformsData(accountID: String, accessToken: String, startDate: Date, endDate: Date) async -> Result<[PlatformData], AdSenseError> {
        guard NetworkMonitor.shared.shouldProceedWithRequest() else {
            return .failure(.requestFailed("No internet connection"))
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let start = dateFormatter.string(from: startDate)
        let end = dateFormatter.string(from: endDate)
        
        // Define the metrics we want to match the dashboard
        let metrics = [
            "ESTIMATED_EARNINGS",
            "PAGE_VIEWS",
            "PAGE_VIEWS_RPM",
            "IMPRESSIONS",
            "IMPRESSIONS_RPM",
            "ACTIVE_VIEW_VIEWABILITY", 
            "CLICKS",
            "AD_REQUESTS",
            "IMPRESSIONS_CTR"
        ]
        
        let metricsQuery = metrics.map { "metrics=\($0)" }.joined(separator: "&")
        
        // Use PLATFORM_TYPE_CODE as the dimension for platform data (AdSense Reporting API v2)
        let dimension = "PLATFORM_TYPE_CODE"
        let urlString = "https://adsense.googleapis.com/v2/\(accountID)/reports:generate?\(metricsQuery)&dimensions=\(dimension)&startDate.year=\(start.prefix(4))&startDate.month=\(start.dropFirst(5).prefix(2))&startDate.day=\(start.suffix(2))&endDate.year=\(end.prefix(4))&endDate.month=\(end.dropFirst(5).prefix(2))&endDate.day=\(end.suffix(2))"
        
        print("Fetching platform data using dimension: \(dimension)")
        print("Full URL: \(urlString)")  // Add URL logging for debugging
        
        guard let url = URL(string: urlString) else {
            return .failure(.requestFailed("Invalid URL"))
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        do {
            try Task.checkCancellation()
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            try Task.checkCancellation()
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.requestFailed("Invalid response"))
            }
            
            print("Platform API Response Status: \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200:
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                guard let rows = json?["rows"] as? [[String: Any]] else {
                    print("No rows found in Platform API response")
                    return .failure(.requestFailed("No data available"))
                }
                
                let platforms = rows.compactMap { row -> PlatformData? in
                    guard let cells = row["cells"] as? [[String: Any]] else { return nil }
                    
                    // The first cell contains the platform value
                    let platform = cells.first?["value"] as? String ?? "Unknown Platform"
                    
                    // Initialize default values
                    var earnings = "0"
                    var pageViews = "0"
                    var pageRPM = "0"
                    var impressions = "0"
                    var impressionsRPM = "0"
                    var activeViewViewable = "0"
                    var clicks = "0"
                    var requests = "0"
                    var ctr = "0"
                    
                    // Map the remaining cells to metrics in order
                    if cells.count >= 2 {
                        earnings = cells[1]["value"] as? String ?? "0"
                    }
                    if cells.count >= 3 {
                        pageViews = cells[2]["value"] as? String ?? "0"
                    }
                    if cells.count >= 4 {
                        pageRPM = cells[3]["value"] as? String ?? "0"
                    }
                    if cells.count >= 5 {
                        impressions = cells[4]["value"] as? String ?? "0"
                    }
                    if cells.count >= 6 {
                        impressionsRPM = cells[5]["value"] as? String ?? "0"
                    }
                    if cells.count >= 7 {
                        activeViewViewable = cells[6]["value"] as? String ?? "0"
                    }
                    if cells.count >= 8 {
                        clicks = cells[7]["value"] as? String ?? "0"
                    }
                    if cells.count >= 9 {
                        requests = cells[8]["value"] as? String ?? "0"
                    }
                    if cells.count >= 10 {
                        ctr = cells[9]["value"] as? String ?? "0"
                    }
                    
                    return PlatformData(
                        platform: platform,
                        earnings: earnings,
                        pageViews: pageViews,
                        pageRPM: pageRPM,
                        impressions: impressions,
                        impressionsRPM: impressionsRPM,
                        activeViewViewable: activeViewViewable,
                        clicks: clicks,
                        requests: requests,
                        ctr: ctr
                    )
                }
                
                // Sort by earnings (highest first)
                let sortedPlatforms = platforms.sorted { 
                    (Double($0.earnings) ?? 0) > (Double($1.earnings) ?? 0)
                }
                
                print("Successfully fetched \(sortedPlatforms.count) platforms")
                return .success(sortedPlatforms)
                
            case 401:
                return .failure(.unauthorized)
            case 403:
                return .failure(.requestFailed("Access forbidden"))
            case 400:
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorJson["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    print("API Error Details: \(message)")
                    return .failure(.requestFailed(message))
                }
                return .failure(.requestFailed("Bad request - invalid dimension or parameters"))
            default:
                return .failure(.requestFailed("HTTP \(httpResponse.statusCode)"))
            }
        } catch {
            print("Error fetching platform data: \(error)")
            return .failure(.requestFailed(error.localizedDescription))
        }
    }
} 