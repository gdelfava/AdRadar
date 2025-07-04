import Foundation
import SwiftUI

@MainActor
class DomainViewModel: ObservableObject {
    @Published var domains: [DomainData] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedFilter: DateFilter = .last7Days
    @Published var hasLoaded = false
    
    var accessToken: String?
    var authViewModel: AuthViewModel?
    private var accountID: String?
    
    init(accessToken: String?) {
        self.accessToken = accessToken
    }
    
    func fetchDomainData() async {
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
            self.domains = mockData.domains
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
        let result = await fetchDomainsData(
            accountID: accountID,
            accessToken: currentToken,
            startDate: dateRange.start,
            endDate: dateRange.end
        )
        
        switch result {
        case .success(let domains):
            self.domains = domains
            self.hasLoaded = true
        case .failure(let error):
            self.error = error.localizedDescription
        }
        
        self.isLoading = false
    }
    
    private func fetchDomainsData(accountID: String, accessToken: String, startDate: Date, endDate: Date) async -> Result<[DomainData], AdSenseError> {
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
        let urlString = "https://adsense.googleapis.com/v2/\(accountID)/reports:generate?\(metricsQuery)&dimensions=DOMAIN_NAME&startDate.year=\(start.prefix(4))&startDate.month=\(start.dropFirst(5).prefix(2))&startDate.day=\(start.suffix(2))&endDate.year=\(end.prefix(4))&endDate.month=\(end.dropFirst(5).prefix(2))&endDate.day=\(end.suffix(2))"
        
        guard let url = URL(string: urlString) else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        do {
            try Task.checkCancellation()
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            try Task.checkCancellation()
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            switch httpResponse.statusCode {
            case 200:
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                guard let rows = json?["rows"] as? [[String: Any]] else {
                    return .success([]) // No data available
                }
                
                let domains = rows.compactMap { row -> DomainData? in
                    guard let cells = row["cells"] as? [[String: Any]] else { return nil }
                    
                    // The first cell contains the domain name
                    let domainName = cells.first?["value"] as? String ?? "Unknown Domain"
                    
                    // Initialize default values
                    var earnings = "0"
                    var requests = "0"
                    var pageViews = "0"
                    var impressions = "0"
                    var clicks = "0"
                    var ctr = "0"
                    var rpm = "0"
                    
                    // Map the remaining cells to metrics
                    // The order should be: domain_name, earnings, requests, page_views, impressions, clicks, ctr, rpm
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
                    
                    return DomainData(
                        domainName: domainName,
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
                let sortedDomains = domains.sorted { 
                    (Double($0.earnings) ?? 0) > (Double($1.earnings) ?? 0)
                }
                
                return .success(sortedDomains)
                
            case 401:
                return .failure(.unauthorized)
            case 403:
                return .failure(.requestFailed("Access forbidden"))
            default:
                return .failure(.requestFailed("Server returned status code \(httpResponse.statusCode)"))
            }
        } catch let error as URLError {
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
            return .failure(.requestFailed("Unexpected error: \(error.localizedDescription)"))
        }
    }
    
    func refreshData() async {
        await fetchDomainData()
    }
} 