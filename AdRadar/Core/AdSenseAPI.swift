import Foundation

// MARK: - Response Models

struct AdSenseSummaryData: Codable {
    let today: String
    let yesterday: String
    let last7Days: String
    let thisMonth: String
    let lastMonth: String
    let lifetime: String
    // Delta values and positivity for each card
    let todayDelta: String?
    let todayDeltaPositive: Bool?
    let yesterdayDelta: String?
    let yesterdayDeltaPositive: Bool?
    let last7DaysDelta: String?
    let last7DaysDeltaPositive: Bool?
    let thisMonthDelta: String?
    let thisMonthDeltaPositive: Bool?
    let lastMonthDelta: String?
    let lastMonthDeltaPositive: Bool?
}

struct AccountsResponse: Codable {
    let accounts: [Account]
}

struct Account: Codable {
    let name: String
    let displayName: String
    let pendingTasks: [String]?
    let timeZone: TimeZone?
    let createTime: String?
    let premium: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name
        case displayName
        case pendingTasks
        case timeZone
        case createTime
        case premium
    }
}

struct TimeZone: Codable {
    let id: String
}

// MARK: - Error Types

enum AdSenseError: Error {
    case invalidURL
    case requestFailed(String)
    case noAccountID
    case unauthorized
    case invalidResponse
    case decodingError(String)
}

class AdSenseAPI {
    static let shared = AdSenseAPI()
    private let urlSession: URLSession
    
    private init() {
        self.urlSession = NetworkMonitor.createURLSession()
    }
    
    func fetchSummaryData(accountID: String, accessToken: String, startDate: Date, endDate: Date) async -> Result<AdSenseSummaryData, AdSenseError> {
        // Check network connection asynchronously
        let isConnected = await Task.detached {
            NetworkMonitor.shared.isConnected
        }.value
        
        guard isConnected else {
            return .failure(.requestFailed("No internet connection"))
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let start = dateFormatter.string(from: startDate)
        let end = dateFormatter.string(from: endDate)
        let urlString = "https://adsense.googleapis.com/v2/\(accountID)/reports:generate?metrics=ESTIMATED_EARNINGS&startDate.year=\(start.prefix(4))&startDate.month=\(start.dropFirst(5).prefix(2))&startDate.day=\(start.suffix(2))&endDate.year=\(end.prefix(4))&endDate.month=\(end.dropFirst(5).prefix(2))&endDate.day=\(end.suffix(2))"
        guard let url = URL(string: urlString) else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        do {
            // Check for cancellation before making the request
            try Task.checkCancellation()
            
            let (data, response) = try await urlSession.data(for: request)
            
            // Check for cancellation after receiving the response
            try Task.checkCancellation()
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            switch httpResponse.statusCode {
            case 200:
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                var earnings: String = "0.00"
                if let rows = json?["rows"] as? [[String: Any]],
                   let firstRow = rows.first,
                   let cells = firstRow["cells"] as? [[String: Any]],
                   let valueString = cells.first?["value"] as? String {
                    earnings = valueString
                }
                let summary = AdSenseSummaryData(
                    today: "",
                    yesterday: "",
                    last7Days: earnings,
                    thisMonth: "",
                    lastMonth: "",
                    lifetime: "",
                    todayDelta: nil,
                    todayDeltaPositive: nil,
                    yesterdayDelta: nil,
                    yesterdayDeltaPositive: nil,
                    last7DaysDelta: nil,
                    last7DaysDeltaPositive: nil,
                    thisMonthDelta: nil,
                    thisMonthDeltaPositive: nil,
                    lastMonthDelta: nil,
                    lastMonthDeltaPositive: nil
                )
                return .success(summary)
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
    
    // Fetch the user's AdSense account ID
    static func fetchAccountID(accessToken: String) async -> Result<String, AdSenseError> {
        // Check network connection and endpoint accessibility
        guard NetworkMonitor.shared.canAccessEndpoints() else {
            return .failure(.requestFailed("Network endpoints are not accessible"))
        }
        
        guard NetworkMonitor.shared.shouldProceedWithRequest() else {
            return .failure(.requestFailed("No internet connection"))
        }
        
        guard let url = URL(string: "https://adsense.googleapis.com/v2/accounts") else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        do {
            // Check for cancellation before making the request
            try Task.checkCancellation()
            
            let urlSession = NetworkMonitor.createURLSession()
            
            // Verify connection state again before making the request
            guard NetworkMonitor.shared.shouldProceedWithRequest() else {
                return .failure(.requestFailed("Lost internet connection"))
            }
            
            let (data, response) = try await urlSession.data(for: request)
            
            // Check for cancellation after receiving the response
            try Task.checkCancellation()
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error: Invalid response type")
                return .failure(.requestFailed("Invalid response type"))
            }
            
            print("HTTP Status Code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response Data: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                // Check if response is empty
                if data.isEmpty || String(data: data, encoding: .utf8) == "{}" {
                    print("Empty response from AdSense API - no accounts found")
                    return .failure(.noAccountID)
                }
                
                do {
                    let decoder = JSONDecoder()
                    let accounts = try decoder.decode(AccountsResponse.self, from: data)
                    if let firstAccount = accounts.accounts.first {
                        let accountID = firstAccount.name
                        // Save the account ID to UserDefaults
                        UserDefaultsManager.shared.setString(accountID, forKey: "adSenseAccountID")
                        return .success(accountID)
                    } else {
                        return .failure(.noAccountID)
                    }
                } catch {
                    print("Decoding error: \(error)")
                    // If decoding fails and we have an empty response, treat as no account
                    if String(data: data, encoding: .utf8) == "{}" {
                        return .failure(.noAccountID)
                    }
                    return .failure(.decodingError(error.localizedDescription))
                }
            case 401:
                return .failure(.unauthorized)
            case 403:
                return .failure(.requestFailed("Access forbidden"))
            default:
                return .failure(.requestFailed("Server returned status code \(httpResponse.statusCode)"))
            }
        } catch {
            print("Network error: \(error)")
            return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
        }
    }
    
    // Fetch earnings for a given date range
    func fetchReport(accessToken: String, accountID: String, startDate: String, endDate: String) async -> Result<Double, AdSenseError> {
        guard NetworkMonitor.shared.isConnected else {
            return .failure(.requestFailed("No internet connection"))
        }
        let urlString = "https://adsense.googleapis.com/v2/\(accountID)/reports:generate?metrics=ESTIMATED_EARNINGS&dateRange=REPORTING_DATE_RANGE_UNSPECIFIED&startDate.year=\(startDate.prefix(4))&startDate.month=\(startDate.dropFirst(5).prefix(2))&startDate.day=\(startDate.suffix(2))&endDate.year=\(endDate.prefix(4))&endDate.month=\(endDate.dropFirst(5).prefix(2))&endDate.day=\(endDate.suffix(2))"
        guard let url = URL(string: urlString) else {
            return .failure(.invalidURL)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        print("Requesting: \(url)")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print("Response: \(String(data: data, encoding: .utf8) ?? "<no data>")")
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return .failure(.requestFailed("Request failed"))
            }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let rows = json?["rows"] as? [[String: Any]],
               let firstRow = rows.first,
               let cells = firstRow["cells"] as? [[String: Any]],
               let valueString = cells.first?["value"] as? String,
               let value = Double(valueString) {
                return .success(value)
            } else {
                return .success(0.0) // No data, treat as zero
            }
        } catch {
            return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
        }
    }
    
    /// Fetches the user's unpaid earnings from AdSense using the payments endpoint (entry with 'unpaid' in the name).
    func fetchUnpaidEarnings(accessToken: String, accountID: String) async -> Result<Double, AdSenseError> {
        guard NetworkMonitor.shared.isConnected else {
            return .failure(.requestFailed("No internet connection"))
        }
        let urlString = "https://adsense.googleapis.com/v2/\(accountID)/payments"
        guard let url = URL(string: urlString) else { return .failure(.invalidURL) }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print("Payments JSON: \(String(data: data, encoding: .utf8) ?? "<no data>")")
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            switch httpResponse.statusCode {
            case 200:
                break // Continue processing
            case 400:
                if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorMessage["error"] as? [String: Any] {
                    let message = error["message"] as? String ?? "Bad request"
                    let status = error["status"] as? String
                    if status == "FAILED_PRECONDITION" {
                        return .failure(.requestFailed("FAILED_PRECONDITION|\(message)"))
                    }
                    return .failure(.requestFailed("API Error: \(message)"))
                }
                return .failure(.requestFailed("Bad request. Please try again later."))
            case 401:
                return .failure(.unauthorized)
            case 403:
                return .failure(.requestFailed("Access forbidden"))
            default:
                return .failure(.requestFailed("Request failed with status \(httpResponse.statusCode)"))
            }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let payments = json?["payments"] as? [[String: Any]] {
                // Find the unpaid entry
                if let unpaid = payments.first(where: { ($0["name"] as? String)?.contains("unpaid") == true }),
                   let amountString = unpaid["amount"] as? String {
                    let cleaned = amountString.replacingOccurrences(of: "[^0-9.-]", with: "", options: .regularExpression)
                    if let value = Double(cleaned) {
                        return .success(value)
                    }
                }
                // If not found, treat as zero
                return .success(0.0)
            } else {
                return .success(0.0)
            }
        } catch {
            return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
        }
    }
    
    /// Fetches the user's previous payment date and amount from AdSense using the payments endpoint.
    func fetchPreviousPayment(accessToken: String, accountID: String) async -> Result<(date: Date, amount: Double)?, AdSenseError> {
        guard NetworkMonitor.shared.isConnected else {
            return .failure(.requestFailed("No internet connection"))
        }
        let urlString = "https://adsense.googleapis.com/v2/\(accountID)/payments"
        guard let url = URL(string: urlString) else { return .failure(.invalidURL) }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print("Payments JSON: \(String(data: data, encoding: .utf8) ?? "<no data>")")
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            switch httpResponse.statusCode {
            case 200:
                break // Continue processing
            case 400:
                if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorMessage["error"] as? [String: Any] {
                    let message = error["message"] as? String ?? "Bad request"
                    let status = error["status"] as? String
                    if status == "FAILED_PRECONDITION" {
                        return .failure(.requestFailed("FAILED_PRECONDITION|\(message)"))
                    }
                    return .failure(.requestFailed("API Error: \(message)"))
                }
                return .failure(.requestFailed("Bad request. Please try again later."))
            case 401:
                return .failure(.unauthorized)
            case 403:
                return .failure(.requestFailed("Access forbidden"))
            default:
                return .failure(.requestFailed("Request failed with status \(httpResponse.statusCode)"))
            }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let payments = json?["payments"] as? [[String: Any]] {
                // Find the most recent payment with a date (not the unpaid one)
                if let paid = payments.first(where: { $0["date"] != nil }),
                   let amountString = paid["amount"] as? String,
                   let dateDict = paid["date"] as? [String: Any],
                   let year = dateDict["year"] as? Int,
                   let month = dateDict["month"] as? Int,
                   let day = dateDict["day"] as? Int {
                    let cleaned = amountString.replacingOccurrences(of: "[^0-9.-]", with: "", options: .regularExpression)
                    if let amount = Double(cleaned) {
                        var dateComponents = DateComponents()
                        dateComponents.year = year
                        dateComponents.month = month
                        dateComponents.day = day
                        let calendar = Calendar.current
                        if let date = calendar.date(from: dateComponents) {
                            return .success((date: date, amount: amount))
                        }
                    }
                }
                // If not found, treat as no previous payment
                return .success(nil)
            } else {
                return .success(nil)
            }
        } catch {
            return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
        }
    }

    /// Fetches the user's payment history from AdSense using the payments endpoint.
    func fetchPaymentHistory(accessToken: String, accountID: String) async -> Result<[(date: Date, amount: Double)], AdSenseError> {
        guard NetworkMonitor.shared.isConnected else {
            return .failure(.requestFailed("No internet connection"))
        }
        let urlString = "https://adsense.googleapis.com/v2/\(accountID)/payments"
        guard let url = URL(string: urlString) else { return .failure(.invalidURL) }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print("Payments JSON: \(String(data: data, encoding: .utf8) ?? "<no data>")")
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            switch httpResponse.statusCode {
            case 200:
                break // Continue processing
            case 401:
                return .failure(.unauthorized)
            case 403:
                return .failure(.requestFailed("Access forbidden"))
            default:
                return .failure(.requestFailed("Request failed with status \(httpResponse.statusCode)"))
            }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let payments = json?["payments"] as? [[String: Any]] {
                // Filter for paid payments only - according to docs, paid payments have names like:
                // accounts/{account}/payments/yyyy-MM-dd
                let paidPayments = payments.compactMap { payment -> (date: Date, amount: Double)? in
                    guard let amountString = payment["amount"] as? String,
                          let dateDict = payment["date"] as? [String: Any],
                          let year = dateDict["year"] as? Int,
                          let month = dateDict["month"] as? Int,
                          let day = dateDict["day"] as? Int else {
                        return nil
                    }
                    
                    // Clean the amount string - remove currency symbol and any non-numeric characters except decimal point
                    let cleaned = amountString.replacingOccurrences(of: "[^0-9.-]", with: "", options: .regularExpression)
                    guard let amount = Double(cleaned) else { return nil }
                    
                    var dateComponents = DateComponents()
                    dateComponents.year = year
                    dateComponents.month = month
                    dateComponents.day = day
                    let calendar = Calendar.current
                    guard let date = calendar.date(from: dateComponents) else { return nil }
                    
                    return (date: date, amount: amount)
                }
                
                // Sort by date descending (most recent first)
                let sortedPayments = paidPayments.sorted { $0.date > $1.date }
                
                // Take only the last 3 payments
                let lastThreePayments = Array(sortedPayments.prefix(3))
                
                return .success(lastThreePayments)
            } else {
                return .success([])
            }
        } catch {
            return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
        }
    }

    /// Lists all payments available in the user's AdSense account
    func listAllPayments(accessToken: String, accountID: String) async -> Result<[(name: String, date: Date?, amount: String)], AdSenseError> {
        guard NetworkMonitor.shared.isConnected else {
            return .failure(.requestFailed("No internet connection"))
        }
        let urlString = "https://adsense.googleapis.com/v2/\(accountID)/payments"
        guard let url = URL(string: urlString) else { return .failure(.invalidURL) }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print("Payments JSON: \(String(data: data, encoding: .utf8) ?? "<no data>")")
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            switch httpResponse.statusCode {
            case 200:
                break // Continue processing
            case 401:
                return .failure(.unauthorized)
            case 403:
                return .failure(.requestFailed("Access forbidden"))
            default:
                return .failure(.requestFailed("Request failed with status \(httpResponse.statusCode)"))
            }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let payments = json?["payments"] as? [[String: Any]] {
                let allPayments = payments.compactMap { payment -> (name: String, date: Date?, amount: String)? in
                    guard let name = payment["name"] as? String,
                          let amount = payment["amount"] as? String else {
                        return nil
                    }
                    
                    // Parse date if it exists
                    var date: Date? = nil
                    if let dateDict = payment["date"] as? [String: Any],
                       let year = dateDict["year"] as? Int,
                       let month = dateDict["month"] as? Int,
                       let day = dateDict["day"] as? Int {
                        var dateComponents = DateComponents()
                        dateComponents.year = year
                        dateComponents.month = month
                        dateComponents.day = day
                        let calendar = Calendar.current
                        date = calendar.date(from: dateComponents)
                    }
                    
                    return (name: name, date: date, amount: amount)
                }
                
                return .success(allPayments)
            } else {
                return .success([])
            }
        } catch {
            return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
        }
    }

    static let appGroupID = "group.com.delteqis.AdRadar"
    
    func fetchAccountInfo(accessToken: String) async -> Result<Account, AdSenseError> {
        guard NetworkMonitor.shared.isConnected else {
            return .failure(.requestFailed("No internet connection"))
        }
        
        guard let url = URL(string: "https://adsense.googleapis.com/v2/accounts") else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            switch httpResponse.statusCode {
            case 200:
                // Check if response is empty
                if data.isEmpty || String(data: data, encoding: .utf8) == "{}" {
                    print("Empty response from AdSense API - no accounts found")
                    return .failure(.noAccountID)
                }
                
                do {
                    let decoder = JSONDecoder()
                    let accounts = try decoder.decode(AccountsResponse.self, from: data)
                    if let firstAccount = accounts.accounts.first {
                        return .success(firstAccount)
                    } else {
                        return .failure(.noAccountID)
                    }
                } catch {
                    print("Decoding error: \(error)")
                    // If decoding fails and we have an empty response, treat as no account
                    if String(data: data, encoding: .utf8) == "{}" {
                        return .failure(.noAccountID)
                    }
                    return .failure(.decodingError(error.localizedDescription))
                }
            case 401:
                return .failure(.unauthorized)
            case 403:
                return .failure(.requestFailed("Access forbidden"))
            default:
                return .failure(.requestFailed("Server returned status code \(httpResponse.statusCode)"))
            }
        } catch {
            return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
        }
    }
    
    func saveSummaryToSharedContainer(_ summary: AdSenseSummaryData) {
        UserDefaultsManager.shared.saveSummaryData(summary)
    }
    
    static func loadSummaryFromSharedContainer() -> AdSenseSummaryData? {
        return UserDefaultsManager.shared.loadSummaryData()
    }
    
    static func loadLastUpdateDate() -> Date? {
        return UserDefaultsManager.shared.getLastUpdateDate()
    }

    /// Fetches all detailed metrics for a given date range
    func fetchMetricsForRange(accountID: String, accessToken: String, startDate: Date, endDate: Date) async -> Result<AdSenseDayMetrics, AdSenseError> {
        guard NetworkMonitor.shared.isConnected else {
            return .failure(.requestFailed("No internet connection"))
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let start = dateFormatter.string(from: startDate)
        let end = dateFormatter.string(from: endDate)
        
        let metrics = [
            "ESTIMATED_EARNINGS",
            "CLICKS",
            "PAGE_VIEWS",
            "IMPRESSIONS",
            "AD_REQUESTS",
            "MATCHED_AD_REQUESTS",
            "COST_PER_CLICK",
            "IMPRESSIONS_CTR",
            "IMPRESSIONS_RPM",
            "PAGE_VIEWS_CTR",
            "PAGE_VIEWS_RPM"
        ]
        let metricsQuery = metrics.map { "metrics=\($0)" }.joined(separator: "&")
        let urlString = "https://adsense.googleapis.com/v2/\(accountID)/reports:generate?\(metricsQuery)&startDate.year=\(start.prefix(4))&startDate.month=\(start.dropFirst(5).prefix(2))&startDate.day=\(start.suffix(2))&endDate.year=\(end.prefix(4))&endDate.month=\(end.dropFirst(5).prefix(2))&endDate.day=\(end.suffix(2))"
        guard let url = URL(string: urlString) else {
            print("[AdSenseAPI] Invalid URL: \(urlString)")
            return .failure(.invalidResponse)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        print("[AdSenseAPI] Requesting: \(urlString)")
        print("[AdSenseAPI] Headers: \(request.allHTTPHeaderFields ?? [:])")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("[AdSenseAPI] HTTP Status: \(httpResponse.statusCode)")
            }
            if let raw = String(data: data, encoding: .utf8) {
                print("[AdSenseAPI] Raw response: \(raw)")
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            switch httpResponse.statusCode {
            case 200:
                break // Continue processing
            case 400:
                if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorMessage["error"] as? [String: Any] {
                    let message = error["message"] as? String ?? "Bad request"
                    let status = error["status"] as? String
                    if status == "NEEDS_ATTENTION" {
                        return .failure(.requestFailed("NEEDS_ATTENTION|\(message)"))
                    }
                    return .failure(.requestFailed("API Error: \(message)"))
                }
                return .failure(.requestFailed("Bad request. Please try again later."))
            default:
                return .failure(.requestFailed("HTTP \(httpResponse.statusCode): \(String(data: data, encoding: .utf8) ?? "No body")"))
            }
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            guard let rows = json?["rows"] as? [[String: Any]], let row = rows.first, let cells = row["cells"] as? [[String: Any]] else {
                print("[AdSenseAPI] No rows/cells in response")
                return .failure(.invalidResponse)
            }
            if cells.count != metrics.count {
                print("[AdSenseAPI] Warning: Expected \(metrics.count) cells, got \(cells.count)")
            }
            func cellValue(_ idx: Int) -> String {
                (cells.indices.contains(idx) ? (cells[idx]["value"] as? String) : nil) ?? "-"
            }
            let metricsObj = AdSenseDayMetrics(
                estimatedEarnings: cellValue(0),
                clicks: cellValue(1),
                pageViews: cellValue(2),
                impressions: cellValue(3),
                adRequests: cellValue(4),
                matchedAdRequests: cellValue(5),
                costPerClick: cellValue(6),
                impressionsCTR: cellValue(7),
                impressionsRPM: cellValue(8),
                pageViewsCTR: cellValue(9),
                pageViewsRPM: cellValue(10)
            )
            return .success(metricsObj)
        } catch {
            print("[AdSenseAPI] Network or parsing error: \(error)")
            return .failure(.requestFailed(error.localizedDescription))
        }
    }
} 