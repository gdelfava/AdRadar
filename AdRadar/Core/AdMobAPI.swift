import Foundation

// MARK: - AdMob Response Models

struct AdMobReportResponse: Codable {
    let header: ReportHeader?
    let row: [AdMobReportRow]?
    
    enum CodingKeys: String, CodingKey {
        case header
        case row
    }
}

// Alternative response structure for direct array responses
typealias AdMobReportArray = [AdMobReportRow]

struct ReportHeader: Codable {
    let dateRange: AdMobDateRange?
    let localizationSettings: LocalizationSettings?
    let reportingTimeZone: String?
    
    enum CodingKeys: String, CodingKey {
        case dateRange
        case localizationSettings
        case reportingTimeZone
    }
}

struct AdMobDateRange: Codable {
    let startDate: AdMobDate?
    let endDate: AdMobDate?
    
    enum CodingKeys: String, CodingKey {
        case startDate
        case endDate
    }
}

struct AdMobDate: Codable {
    let year: Int?
    let month: Int?
    let day: Int?
}

struct LocalizationSettings: Codable {
    let currencyCode: String?
    let languageCode: String?
    
    enum CodingKeys: String, CodingKey {
        case currencyCode
        case languageCode
    }
}

struct AdMobReportRow: Codable {
    let dimensionValues: [String: AdMobDimensionValue]?
    let metricValues: [String: AdMobMetricValue]?
    
    enum CodingKeys: String, CodingKey {
        case dimensionValues
        case metricValues
    }
}

struct AdMobDimensionValue: Codable {
    let value: String?
    let displayLabel: String?
    
    enum CodingKeys: String, CodingKey {
        case value
        case displayLabel
    }
}

struct AdMobMetricValue: Codable {
    let integerValue: String?
    let doubleValue: Double?
    let microsValue: String?
    
    enum CodingKeys: String, CodingKey {
        case integerValue
        case doubleValue
        case microsValue
    }
}

struct AdMobAccountsResponse: Codable {
    let account: [AdMobAccount]?
    
    enum CodingKeys: String, CodingKey {
        case account
    }
}

struct AdMobAccount: Codable {
    let publisherId: String?
    let name: String?
    let currencyCode: String?
    let reportingTimeZone: String?
    
    enum CodingKeys: String, CodingKey {
        case publisherId
        case name
        case currencyCode
        case reportingTimeZone
    }
}

// MARK: - Error Types

enum AdMobError: Error {
    case invalidURL
    case requestFailed(String)
    case noAccountID
    case unauthorized
    case invalidResponse
    case decodingError(String)
    case noData
}

// MARK: - AdMob API Service

class AdMobAPI {
    static let shared = AdMobAPI()
    private let urlSession: URLSession
    
    private init() {
        self.urlSession = NetworkMonitor.createURLSession()
    }
    
    /// Fetches the user's AdMob account ID
    static func fetchAccountID(accessToken: String) async -> Result<String, AdMobError> {
        // Check network connection asynchronously
        let isConnected = await Task.detached {
            NetworkMonitor.shared.isConnected
        }.value
        
        guard isConnected else {
            return .failure(.requestFailed("No internet connection"))
        }
        
        guard let url = URL(string: "https://admob.googleapis.com/v1/accounts") else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        do {
            try Task.checkCancellation()
            
            let urlSession = NetworkMonitor.createURLSession()
            let (data, response) = try await urlSession.data(for: request)
            
            try Task.checkCancellation()
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("AdMob API Error: Invalid response type")
                return .failure(.requestFailed("Invalid response type"))
            }
            
            print("AdMob Accounts HTTP Status Code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("AdMob Accounts Response Data: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let accounts = try decoder.decode(AdMobAccountsResponse.self, from: data)
                    if let firstAccount = accounts.account?.first,
                       let publisherId = firstAccount.publisherId {
                        return .success(publisherId)
                    } else {
                        return .failure(.noAccountID)
                    }
                } catch {
                    print("AdMob Accounts Decoding error: \(error)")
                    return .failure(.decodingError(error.localizedDescription))
                }
            case 401:
                // Check for specific UNAUTHENTICATED status
                if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorMessage["error"] as? [String: Any] {
                    let message = error["message"] as? String ?? "Authentication required"
                    let status = error["status"] as? String
                    if status == "UNAUTHENTICATED" {
                        return .failure(.requestFailed("UNAUTHENTICATED|\(message)"))
                    }
                    return .failure(.requestFailed("Authentication Error: \(message)"))
                }
                return .failure(.unauthorized)
            case 403:
                return .failure(.requestFailed("Access forbidden. Please check your AdMob permissions."))
            case 429:
                return .failure(.requestFailed("Rate limit exceeded. Please try again later."))
            case 500...599:
                return .failure(.requestFailed("AdMob API server error. Please try again later."))
            default:
                return .failure(.requestFailed("Unexpected error: HTTP \(httpResponse.statusCode)"))
            }
        } catch let error as URLError where error.code == .cancelled {
            print("AdMob request was cancelled")
            return .failure(.requestFailed("Request was cancelled"))
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                return .failure(.requestFailed("No internet connection"))
            case .timedOut:
                return .failure(.requestFailed("Request timed out"))
            case .cannotConnectToHost:
                return .failure(.requestFailed("Cannot connect to server"))
            default:
                return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
            }
        } catch {
            print("AdMob Network error: \(error)")
            return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
        }
    }
    
    /// Fetches apps data from AdMob API
    func fetchAppsReport(accountID: String, accessToken: String, startDate: Date, endDate: Date) async -> Result<AdMobReportResponse, AdMobError> {
        guard NetworkMonitor.shared.shouldProceedWithRequest() else {
            return .failure(.requestFailed("No internet connection"))
        }
        
        let requestBody = [
            "reportSpec": [
                "dateRange": [
                    "startDate": [
                        "year": Calendar.current.component(.year, from: startDate),
                        "month": Calendar.current.component(.month, from: startDate),
                        "day": Calendar.current.component(.day, from: startDate)
                    ],
                    "endDate": [
                        "year": Calendar.current.component(.year, from: endDate),
                        "month": Calendar.current.component(.month, from: endDate),
                        "day": Calendar.current.component(.day, from: endDate)
                    ]
                ],
                "dimensions": ["APP"],
                "metrics": ["ESTIMATED_EARNINGS", "IMPRESSIONS", "CLICKS", "IMPRESSION_CTR", "AD_REQUESTS"]
            ]
        ] as [String: Any]
        
        guard let url = URL(string: "https://admob.googleapis.com/v1/accounts/\(accountID)/mediationReport:generate") else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            request.httpBody = jsonData
            
            try Task.checkCancellation()
            
            let (data, response) = try await urlSession.data(for: request)
            
            try Task.checkCancellation()
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            print("AdMob Apps Report HTTP Status Code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("AdMob Apps Report Response: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                // First, let's see what the raw JSON structure looks like
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                    print("Raw AdMob JSON structure: \(type(of: jsonObject))")
                    
                    if let jsonDict = jsonObject as? [String: Any] {
                        print("Response is a dictionary with keys: \(Array(jsonDict.keys))")
                        print("Full dictionary: \(jsonDict)")
                        
                        // Try to decode as our expected structure
                        let decoder = JSONDecoder()
                        let reportResponse = try decoder.decode(AdMobReportResponse.self, from: data)
                        return .success(reportResponse)
                        
                    } else if let jsonArray = jsonObject as? [[String: Any]] {
                        print("Response is an array with \(jsonArray.count) elements")
                        print("First element structure: \(jsonArray.first ?? [:])")
                        
                        // Create a simplified response - we'll parse the raw data manually
                        var appDataList: [AdMobReportRow] = []
                        
                        for item in jsonArray {
                            // Extract basic info for now - we'll refine this based on the actual structure
                            if let dimensionValues = item["dimensionValues"] as? [String: [String: Any]],
                               let metricValues = item["metricValues"] as? [String: [String: Any]] {
                                
                                // Convert to our expected format
                                var convertedDimensions: [String: AdMobDimensionValue] = [:]
                                for (key, value) in dimensionValues {
                                    if let valueStr = value["value"] as? String,
                                       let displayLabel = value["displayLabel"] as? String {
                                        convertedDimensions[key] = AdMobDimensionValue(value: valueStr, displayLabel: displayLabel)
                                    }
                                }
                                
                                var convertedMetrics: [String: AdMobMetricValue] = [:]
                                for (key, value) in metricValues {
                                    let metricValue = AdMobMetricValue(
                                        integerValue: value["integerValue"] as? String,
                                        doubleValue: value["doubleValue"] as? Double,
                                        microsValue: value["microsValue"] as? String
                                    )
                                    convertedMetrics[key] = metricValue
                                }
                                
                                let row = AdMobReportRow(
                                    dimensionValues: convertedDimensions,
                                    metricValues: convertedMetrics
                                )
                                appDataList.append(row)
                            }
                        }
                        
                        let reportResponse = AdMobReportResponse(header: nil, row: appDataList)
                        return .success(reportResponse)
                        
                    } else {
                        print("Unexpected JSON structure: \(jsonObject)")
                        return .failure(.invalidResponse)
                    }
                    
                } catch {
                    print("AdMob JSON parsing error: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Raw AdMob response: \(responseString)")
                    }
                    return .failure(.decodingError(error.localizedDescription))
                }
            case 401:
                // Check for specific UNAUTHENTICATED status
                if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorMessage["error"] as? [String: Any] {
                    let message = error["message"] as? String ?? "Authentication required"
                    let status = error["status"] as? String
                    if status == "UNAUTHENTICATED" {
                        return .failure(.requestFailed("UNAUTHENTICATED|\(message)"))
                    }
                    return .failure(.requestFailed("Authentication Error: \(message)"))
                }
                return .failure(.unauthorized)
            case 403:
                return .failure(.requestFailed("Access forbidden. Please check your AdMob permissions."))
            case 429:
                return .failure(.requestFailed("Rate limit exceeded. Please try again later."))
            case 500...599:
                return .failure(.requestFailed("AdMob API server error. Please try again later."))
            default:
                return .failure(.requestFailed("Unexpected error: HTTP \(httpResponse.statusCode)"))
            }
        } catch let error as URLError where error.code == .cancelled {
            print("AdMob request was cancelled")
            return .failure(.requestFailed("Request was cancelled"))
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                return .failure(.requestFailed("No internet connection"))
            case .timedOut:
                return .failure(.requestFailed("Request timed out"))
            case .cannotConnectToHost:
                return .failure(.requestFailed("Cannot connect to server"))
            default:
                return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
            }
        } catch {
            print("AdMob Network error: \(error)")
            return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
        }
    }
    
    /// Fetches ad units data for a specific app from AdMob API
    func fetchAdUnitsReport(accountID: String, appId: String, accessToken: String, startDate: Date, endDate: Date) async -> Result<AdMobReportResponse, AdMobError> {
        guard NetworkMonitor.shared.shouldProceedWithRequest() else {
            return .failure(.requestFailed("No internet connection"))
        }
        
        let requestBody = [
            "reportSpec": [
                "dateRange": [
                    "startDate": [
                        "year": Calendar.current.component(.year, from: startDate),
                        "month": Calendar.current.component(.month, from: startDate),
                        "day": Calendar.current.component(.day, from: startDate)
                    ],
                    "endDate": [
                        "year": Calendar.current.component(.year, from: endDate),
                        "month": Calendar.current.component(.month, from: endDate),
                        "day": Calendar.current.component(.day, from: endDate)
                    ]
                ],
                "dimensions": ["AD_UNIT", "FORMAT"],
                "metrics": ["ESTIMATED_EARNINGS", "IMPRESSIONS", "CLICKS", "IMPRESSION_CTR", "AD_REQUESTS"],
                "dimensionFilters": [
                    [
                        "dimension": "APP",
                        "matchesAny": [
                            "values": [appId]
                        ]
                    ]
                ]
            ]
        ] as [String: Any]
        
        guard let url = URL(string: "https://admob.googleapis.com/v1/accounts/\(accountID)/mediationReport:generate") else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            request.httpBody = jsonData
            
            try Task.checkCancellation()
            
            let (data, response) = try await urlSession.data(for: request)
            
            try Task.checkCancellation()
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            print("AdMob Ad Units Report HTTP Status Code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("AdMob Ad Units Report Response: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                // First, let's see what the raw JSON structure looks like
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                    print("Raw AdMob Ad Units JSON structure: \(type(of: jsonObject))")
                    
                    if let jsonDict = jsonObject as? [String: Any] {
                        print("Response is a dictionary with keys: \(Array(jsonDict.keys))")
                        print("Full dictionary: \(jsonDict)")
                        
                        // Try to decode as our expected structure
                        let decoder = JSONDecoder()
                        let reportResponse = try decoder.decode(AdMobReportResponse.self, from: data)
                        return .success(reportResponse)
                        
                    } else if let jsonArray = jsonObject as? [[String: Any]] {
                        print("Response is an array with \(jsonArray.count) elements")
                        print("First element structure: \(jsonArray.first ?? [:])")
                        
                        // Create a simplified response - we'll parse the raw data manually
                        var adUnitDataList: [AdMobReportRow] = []
                        
                        for item in jsonArray {
                            // Extract basic info for now - we'll refine this based on the actual structure
                            if let dimensionValues = item["dimensionValues"] as? [String: [String: Any]],
                               let metricValues = item["metricValues"] as? [String: [String: Any]] {
                                
                                // Convert to our expected format
                                var convertedDimensions: [String: AdMobDimensionValue] = [:]
                                for (key, value) in dimensionValues {
                                    if let valueStr = value["value"] as? String,
                                       let displayLabel = value["displayLabel"] as? String {
                                        convertedDimensions[key] = AdMobDimensionValue(value: valueStr, displayLabel: displayLabel)
                                    }
                                }
                                
                                var convertedMetrics: [String: AdMobMetricValue] = [:]
                                for (key, value) in metricValues {
                                    let metricValue = AdMobMetricValue(
                                        integerValue: value["integerValue"] as? String,
                                        doubleValue: value["doubleValue"] as? Double,
                                        microsValue: value["microsValue"] as? String
                                    )
                                    convertedMetrics[key] = metricValue
                                }
                                
                                let row = AdMobReportRow(
                                    dimensionValues: convertedDimensions,
                                    metricValues: convertedMetrics
                                )
                                adUnitDataList.append(row)
                            }
                        }
                        
                        let reportResponse = AdMobReportResponse(header: nil, row: adUnitDataList)
                        return .success(reportResponse)
                        
                    } else {
                        print("Unexpected JSON structure: \(jsonObject)")
                        return .failure(.invalidResponse)
                    }
                    
                } catch {
                    print("AdMob Ad Units JSON parsing error: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Raw AdMob Ad Units response: \(responseString)")
                    }
                    return .failure(.decodingError(error.localizedDescription))
                }
            case 401:
                // Check for specific UNAUTHENTICATED status
                if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorMessage["error"] as? [String: Any] {
                    let message = error["message"] as? String ?? "Authentication required"
                    let status = error["status"] as? String
                    if status == "UNAUTHENTICATED" {
                        return .failure(.requestFailed("UNAUTHENTICATED|\(message)"))
                    }
                    return .failure(.requestFailed("Authentication Error: \(message)"))
                }
                return .failure(.unauthorized)
            case 403:
                return .failure(.requestFailed("Access forbidden. Please check your AdMob permissions."))
            case 429:
                return .failure(.requestFailed("Rate limit exceeded. Please try again later."))
            case 500...599:
                return .failure(.requestFailed("AdMob API server error. Please try again later."))
            default:
                return .failure(.requestFailed("Unexpected error: HTTP \(httpResponse.statusCode)"))
            }
        } catch let error as URLError where error.code == .cancelled {
            print("AdMob Ad Units request was cancelled")
            return .failure(.requestFailed("Request was cancelled"))
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                return .failure(.requestFailed("No internet connection"))
            case .timedOut:
                return .failure(.requestFailed("Request timed out"))
            case .cannotConnectToHost:
                return .failure(.requestFailed("Cannot connect to server"))
            default:
                return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
            }
        } catch {
            print("AdMob Ad Units Network error: \(error)")
            return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
        }
    }
    
    /// Fetches countries data for a specific app from AdMob API
    func fetchCountriesReport(accountID: String, appId: String, accessToken: String, startDate: Date, endDate: Date) async -> Result<AdMobReportResponse, AdMobError> {
        guard NetworkMonitor.shared.shouldProceedWithRequest() else {
            return .failure(.requestFailed("No internet connection"))
        }
        
        let requestBody = [
            "reportSpec": [
                "dateRange": [
                    "startDate": [
                        "year": Calendar.current.component(.year, from: startDate),
                        "month": Calendar.current.component(.month, from: startDate),
                        "day": Calendar.current.component(.day, from: startDate)
                    ],
                    "endDate": [
                        "year": Calendar.current.component(.year, from: endDate),
                        "month": Calendar.current.component(.month, from: endDate),
                        "day": Calendar.current.component(.day, from: endDate)
                    ]
                ],
                "dimensions": ["COUNTRY"],
                "metrics": ["ESTIMATED_EARNINGS", "IMPRESSIONS", "CLICKS", "IMPRESSION_CTR", "AD_REQUESTS"],
                "dimensionFilters": [
                    [
                        "dimension": "APP",
                        "matchesAny": [
                            "values": [appId]
                        ]
                    ]
                ]
            ]
        ] as [String: Any]
        
        guard let url = URL(string: "https://admob.googleapis.com/v1/accounts/\(accountID)/mediationReport:generate") else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            request.httpBody = jsonData
            
            try Task.checkCancellation()
            
            let (data, response) = try await urlSession.data(for: request)
            
            try Task.checkCancellation()
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            print("AdMob Countries Report HTTP Status Code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("AdMob Countries Report Response: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                // First, let's see what the raw JSON structure looks like
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                    print("Raw AdMob Countries JSON structure: \(type(of: jsonObject))")
                    
                    if let jsonDict = jsonObject as? [String: Any] {
                        print("Response is a dictionary with keys: \(Array(jsonDict.keys))")
                        print("Full dictionary: \(jsonDict)")
                        
                        // Try to decode as our expected structure
                        let decoder = JSONDecoder()
                        let reportResponse = try decoder.decode(AdMobReportResponse.self, from: data)
                        return .success(reportResponse)
                        
                    } else if let jsonArray = jsonObject as? [[String: Any]] {
                        print("Response is an array with \(jsonArray.count) elements")
                        print("First element structure: \(jsonArray.first ?? [:])")
                        
                        // Create a simplified response - we'll parse the raw data manually
                        var countryDataList: [AdMobReportRow] = []
                        
                        for item in jsonArray {
                            // Extract basic info for now - we'll refine this based on the actual structure
                            if let dimensionValues = item["dimensionValues"] as? [String: [String: Any]],
                               let metricValues = item["metricValues"] as? [String: [String: Any]] {
                                
                                // Convert to our expected format
                                var convertedDimensions: [String: AdMobDimensionValue] = [:]
                                for (key, value) in dimensionValues {
                                    if let valueStr = value["value"] as? String,
                                       let displayLabel = value["displayLabel"] as? String {
                                        convertedDimensions[key] = AdMobDimensionValue(value: valueStr, displayLabel: displayLabel)
                                    }
                                }
                                
                                var convertedMetrics: [String: AdMobMetricValue] = [:]
                                for (key, value) in metricValues {
                                    let metricValue = AdMobMetricValue(
                                        integerValue: value["integerValue"] as? String,
                                        doubleValue: value["doubleValue"] as? Double,
                                        microsValue: value["microsValue"] as? String
                                    )
                                    convertedMetrics[key] = metricValue
                                }
                                
                                let row = AdMobReportRow(
                                    dimensionValues: convertedDimensions,
                                    metricValues: convertedMetrics
                                )
                                countryDataList.append(row)
                            }
                        }
                        
                        let reportResponse = AdMobReportResponse(header: nil, row: countryDataList)
                        return .success(reportResponse)
                        
                    } else {
                        print("Unexpected JSON structure: \(jsonObject)")
                        return .failure(.invalidResponse)
                    }
                    
                } catch {
                    print("AdMob Countries JSON parsing error: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Raw AdMob Countries response: \(responseString)")
                    }
                    return .failure(.decodingError(error.localizedDescription))
                }
            case 401:
                // Check for specific UNAUTHENTICATED status
                if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorMessage["error"] as? [String: Any] {
                    let message = error["message"] as? String ?? "Authentication required"
                    let status = error["status"] as? String
                    if status == "UNAUTHENTICATED" {
                        return .failure(.requestFailed("UNAUTHENTICATED|\(message)"))
                    }
                    return .failure(.requestFailed("Authentication Error: \(message)"))
                }
                return .failure(.unauthorized)
            case 403:
                return .failure(.requestFailed("Access forbidden. Please check your AdMob permissions."))
            case 429:
                return .failure(.requestFailed("Rate limit exceeded. Please try again later."))
            case 500...599:
                return .failure(.requestFailed("AdMob API server error. Please try again later."))
            default:
                return .failure(.requestFailed("Unexpected error: HTTP \(httpResponse.statusCode)"))
            }
        } catch let error as URLError where error.code == .cancelled {
            print("AdMob Countries request was cancelled")
            return .failure(.requestFailed("Request was cancelled"))
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                return .failure(.requestFailed("No internet connection"))
            case .timedOut:
                return .failure(.requestFailed("Request timed out"))
            case .cannotConnectToHost:
                return .failure(.requestFailed("Cannot connect to server"))
            default:
                return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
            }
        } catch {
            print("AdMob Countries Network error: \(error)")
            return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
        }
    }
} 