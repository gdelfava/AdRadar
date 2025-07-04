import Foundation

struct AppData: Identifiable, Codable, Equatable {
    let id = UUID()
    let appName: String
    let appId: String
    let earnings: String
    let impressions: String
    let clicks: String
    let ctr: String
    let rpm: String
    let requests: String
    
    // Computed properties for formatted display
    var formattedEarnings: String {
        guard let value = Double(earnings) else { return earnings }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: value)) ?? earnings
    }
    
    var formattedCTR: String {
        guard let value = Double(ctr) else { return ctr }
        return String(format: "%.2f%%", value * 100)
    }
    
    var formattedRPM: String {
        guard let value = Double(rpm) else { return rpm }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: value)) ?? rpm
    }
    
    // Helper method to create AppData from AdMob API response
    static func fromAdMobResponse(_ row: AdMobReportRow) -> AppData? {
        guard let dimensionValues = row.dimensionValues,
              let metricValues = row.metricValues else { return nil }
        
        // Extract app information from dimensions
        let appDimension = dimensionValues["APP"]
        let appName = appDimension?.displayLabel ?? appDimension?.value ?? "Unknown App"
        let appId = appDimension?.value ?? ""
        
        // Extract metrics with proper value extraction
        let earnings = extractMetricValue(from: metricValues["ESTIMATED_EARNINGS"])
        let impressions = extractMetricValue(from: metricValues["IMPRESSIONS"])
        let clicks = extractMetricValue(from: metricValues["CLICKS"])
        let ctr = extractMetricValue(from: metricValues["IMPRESSION_CTR"])
        let requests = extractMetricValue(from: metricValues["AD_REQUESTS"])
        
        // Calculate RPM manually from earnings and impressions
        let rpm = calculateRPM(earnings: earnings, impressions: impressions)
        
        return AppData(
            appName: appName,
            appId: appId,
            earnings: earnings,
            impressions: impressions,
            clicks: clicks,
            ctr: ctr,
            rpm: rpm,
            requests: requests
        )
    }
    
    private static func extractMetricValue(from metricValue: AdMobMetricValue?) -> String {
        guard let metricValue = metricValue else { return "0" }
        
        // Try different value types in order of preference
        if let doubleValue = metricValue.doubleValue {
            return String(doubleValue)
        } else if let integerValue = metricValue.integerValue {
            return integerValue
        } else if let microsValue = metricValue.microsValue {
            // Convert microseconds to regular value (divide by 1,000,000)
            if let microsDouble = Double(microsValue) {
                return String(microsDouble / 1_000_000.0)
            }
            return microsValue
        }
        
        return "0"
    }
    
    private static func calculateRPM(earnings: String, impressions: String) -> String {
        guard let earningsValue = Double(earnings),
              let impressionsValue = Double(impressions),
              impressionsValue > 0 else {
            return "0"
        }
        
        // RPM = (Earnings / Impressions) * 1000
        let rpm = (earningsValue / impressionsValue) * 1000
        return String(rpm)
    }
    
    enum CodingKeys: String, CodingKey {
        case appName
        case appId
        case earnings
        case impressions
        case clicks
        case ctr
        case rpm
        case requests
    }
} 