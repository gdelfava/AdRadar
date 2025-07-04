import Foundation
import SwiftUI

@MainActor
class AdNetworkViewModel: ObservableObject {
    @Published var adNetworks: [AdNetworkData] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedFilter: DateFilter = .last7Days
    @Published var hasLoaded = false
    @Published var showEmptyState = false
    @Published var emptyStateMessage = ""
    
    var accessToken: String?
    var authViewModel: AuthViewModel?
    private var accountID: String?
    
    init(accessToken: String?) {
        self.accessToken = accessToken
    }
    
    func fetchAdNetworkData() async {
        guard let currentToken = accessToken else {
            showEmptyState = true
            emptyStateMessage = "Please sign in to view your ad network data"
            error = nil
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
            self.adNetworks = mockData.adNetworks
            self.isLoading = false
            self.error = nil
            self.hasLoaded = true
            self.showEmptyState = false
            return
        }
        
        // Get account ID if not already available
        if accountID == nil {
            let accountResult = await AdSenseAPI.fetchAccountID(accessToken: currentToken)
            switch accountResult {
            case .success(let id):
                self.accountID = id
            case .failure(let error):
                switch error {
                case .unauthorized:
                    showEmptyState = true
                    emptyStateMessage = "Please sign in to view your ad network data"
                    self.error = nil
                case .noAccountID:
                    showEmptyState = true
                    emptyStateMessage = "No AdSense account found. Please make sure you have an active AdSense account."
                    self.error = nil
                case .requestFailed(_):
                    showEmptyState = true
                    emptyStateMessage = "Unable to load ad network data. Please try again later."
                    self.error = nil
                case .invalidURL, .invalidResponse, .decodingError:
                    showEmptyState = true
                    emptyStateMessage = "Unable to load ad network data. Please try again later."
                    self.error = nil
                }
                self.isLoading = false
                return
            }
        }
        
        guard let accountID = self.accountID else {
            self.error = "No AdSense account found. Please make sure you have an active AdSense account."
            self.isLoading = false
            return
        }
        
        self.isLoading = true
        self.error = nil
        
        let dateRange = selectedFilter.dateRange
        let result = await fetchAdNetworksData(
            accountID: accountID,
            accessToken: currentToken,
            startDate: dateRange.start,
            endDate: dateRange.end
        )
        
        switch result {
        case .success(let adNetworks):
            self.adNetworks = adNetworks
            self.hasLoaded = true
            if adNetworks.isEmpty {
                self.error = "No ad network data available for the selected time period."
            }
        case .failure(let error):
            switch error {
            case .unauthorized:
                self.error = "Session expired. Please sign in again."
                Task { @MainActor in
                    authViewModel?.signOut()
                }
            case .noAccountID:
                self.error = "No AdSense account found. Please make sure you have an active AdSense account."
            case .requestFailed(let message):
                if message.contains("No internet") {
                    self.error = "No internet connection. Please check your connection and try again."
                } else if message.contains("timed out") {
                    self.error = "Request timed out. Please try again."
                } else if message.contains("forbidden") {
                    self.error = "Access denied. Please check your AdSense permissions."
                } else {
                    self.error = message
                }
            case .invalidURL:
                self.error = "Invalid API configuration. Please try again later."
            case .invalidResponse:
                self.error = "Invalid response from AdSense. Please try again later."
            case .decodingError(let message):
                self.error = "Data parsing error: \(message)"
            }
        }
        
        self.isLoading = false
    }
    
    private func fetchAdNetworksData(accountID: String, accessToken: String, startDate: Date, endDate: Date) async -> Result<[AdNetworkData], AdSenseError> {
        guard NetworkMonitor.shared.shouldProceedWithRequest() else {
            return .failure(.requestFailed("No internet connection. Please check your connection and try again."))
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
        
        // Build the URL with proper API v2 structure
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "adsense.googleapis.com"
        urlComponents.path = "/v2/\(accountID)/reports:generate"
        
        // Add query parameters
        var queryItems: [URLQueryItem] = []
        
        // Add metrics
        for metric in metrics {
            queryItems.append(URLQueryItem(name: "metrics", value: metric))
        }
        
        // Add dimensions
        queryItems.append(URLQueryItem(name: "dimensions", value: "BUYER_NETWORK_NAME"))
        
        // Add date parameters in the correct format
        let startComponents = start.split(separator: "-")
        let endComponents = end.split(separator: "-")
        
        if startComponents.count == 3 {
            queryItems.append(URLQueryItem(name: "startDate.year", value: String(startComponents[0])))
            queryItems.append(URLQueryItem(name: "startDate.month", value: String(startComponents[1])))
            queryItems.append(URLQueryItem(name: "startDate.day", value: String(startComponents[2])))
        }
        
        if endComponents.count == 3 {
            queryItems.append(URLQueryItem(name: "endDate.year", value: String(endComponents[0])))
            queryItems.append(URLQueryItem(name: "endDate.month", value: String(endComponents[1])))
            queryItems.append(URLQueryItem(name: "endDate.day", value: String(endComponents[2])))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            print("Error: Invalid URL components")
            return .failure(.invalidURL)
        }
        
        print("Ad Network API URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        do {
            try Task.checkCancellation()
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            try Task.checkCancellation()
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error: Invalid response type")
                return .failure(.invalidResponse)
            }
            
            print("Ad Network API Response - Status Code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Ad Network API Response Data: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    guard let rows = json?["rows"] as? [[String: Any]] else {
                        print("No rows found in response")
                        return .success([]) // No data available
                    }
                    
                    let adNetworks = rows.compactMap { row -> AdNetworkData? in
                        guard let cells = row["cells"] as? [[String: Any]] else {
                            print("Invalid cells format in row")
                            return nil
                        }
                        
                        // The first cell contains the ad network name
                        let adNetworkName = cells.first?["value"] as? String ?? "Unknown"
                        
                        // Use the ad network name directly
                        let adNetworkType = adNetworkName
                        
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
                        
                        return AdNetworkData(
                            adNetworkType: adNetworkType,
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
                    let sortedAdNetworks = adNetworks.sorted { 
                        (Double($0.earnings) ?? 0) > (Double($1.earnings) ?? 0)
                    }
                    
                    return .success(sortedAdNetworks)
                } catch {
                    print("JSON parsing error: \(error)")
                    return .failure(.decodingError("Failed to parse response data"))
                }
                
            case 400:
                if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorMessage["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    return .failure(.requestFailed("API Error: \(message)"))
                }
                return .failure(.requestFailed("Bad request. Please try again later."))
            case 401:
                return .failure(.unauthorized)
            case 403:
                return .failure(.requestFailed("Access forbidden. Please check your AdSense permissions."))
            case 429:
                return .failure(.requestFailed("Rate limit exceeded. Please try again later."))
            case 500...599:
                return .failure(.requestFailed("AdSense API server error. Please try again later."))
            default:
                return .failure(.requestFailed("Server returned unexpected status code \(httpResponse.statusCode)"))
            }
        } catch let error as URLError {
            print("URLError: \(error)")
            switch error.code {
            case .notConnectedToInternet:
                return .failure(.requestFailed("No internet connection"))
            case .timedOut:
                return .failure(.requestFailed("Request timed out"))
            case .cannotConnectToHost:
                return .failure(.requestFailed("Cannot connect to server"))
            case .cancelled:
                return .failure(.requestFailed("Request was cancelled"))
            default:
                return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
            }
        } catch {
            print("Unexpected error: \(error)")
            return .failure(.requestFailed("Unexpected error: \(error.localizedDescription)"))
        }
    }
    
    func refreshData() async {
        await fetchAdNetworkData()
    }
} 