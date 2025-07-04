import Foundation
import SwiftUI

// MARK: - Ad Unit Filter Types
enum AdUnitMetricFilter: String, CaseIterable {
    case earnings = "Earnings"
    case clicks = "Clicks"
    case impressions = "Impressions"
    case requests = "Requests"
    case eCPM = "eCPM"
    
    var systemImage: String {
        switch self {
        case .earnings:
            return "dollarsign.circle.fill"
        case .clicks:
            return "cursorarrow.click.2"
        case .impressions:
            return "eye.fill"
        case .requests:
            return "doc.text.fill"
        case .eCPM:
            return "chart.line.uptrend.xyaxis"
        }
    }
    
    var color: Color {
        switch self {
        case .earnings:
            return .green
        case .clicks:
            return .orange
        case .impressions:
            return .blue
        case .requests:
            return .indigo
        case .eCPM:
            return .pink
        }
    }
}

// MARK: - Ad Unit Data Model
struct AdUnitData: Identifiable, Codable, Equatable {
    let id = UUID()
    let adUnitName: String
    let adUnitId: String
    let adUnitFormat: String
    let adType: String
    let earnings: String
    let impressions: String
    let clicks: String
    let ctr: String
    let eCPM: String
    let requests: String
    
    // Computed properties for formatted display
    func formattedEarnings(isDemoMode: Bool = false) -> String {
        guard let value = Double(earnings) else { return earnings }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        if isDemoMode {
            formatter.currencySymbol = "$"
            formatter.locale = Locale(identifier: "en_US")
        } else {
            formatter.locale = Locale.current
        }
        
        return formatter.string(from: NSNumber(value: value)) ?? earnings
    }
    
    // Legacy computed property for backwards compatibility
    var formattedEarnings: String {
        return formattedEarnings(isDemoMode: false)
    }
    
    var formattedCTR: String {
        guard let value = Double(ctr) else { return ctr }
        return String(format: "%.2f%%", value * 100)
    }
    
    func formattedECPM(isDemoMode: Bool = false) -> String {
        guard let value = Double(eCPM) else { return eCPM }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        if isDemoMode {
            formatter.currencySymbol = "$"
            formatter.locale = Locale(identifier: "en_US")
        } else {
            formatter.locale = Locale.current
        }
        
        return formatter.string(from: NSNumber(value: value)) ?? eCPM
    }
    
    // Legacy computed property for backwards compatibility
    var formattedECPM: String {
        return formattedECPM(isDemoMode: false)
    }
    
    var displayDescription: String {
        return "\(adUnitFormat) | \(adType)"
    }
    
    // Helper method to create AdUnitData from AdMob API response
    static func fromAdMobResponse(_ row: AdMobReportRow) -> AdUnitData? {
        guard let dimensionValues = row.dimensionValues,
              let metricValues = row.metricValues else { return nil }
        
        // Extract ad unit information from dimensions
        let adUnitDimension = dimensionValues["AD_UNIT"]
        let adUnitName = adUnitDimension?.displayLabel ?? adUnitDimension?.value ?? "Unknown Ad Unit"
        let adUnitId = adUnitDimension?.value ?? ""
        
        // Extract format information (you may need to adjust these based on actual API response)
        let formatDimension = dimensionValues["FORMAT"]
        let adUnitFormat = formatDimension?.displayLabel ?? formatDimension?.value ?? "Banner"
        
        // For now, we'll set adType to match format, but this can be refined based on actual API response
        let adType = "Banner" // This should be extracted from API response if available
        
        // Extract metrics with proper value extraction
        let earnings = extractMetricValue(from: metricValues["ESTIMATED_EARNINGS"])
        let impressions = extractMetricValue(from: metricValues["IMPRESSIONS"])
        let clicks = extractMetricValue(from: metricValues["CLICKS"])
        let ctr = extractMetricValue(from: metricValues["IMPRESSION_CTR"])
        let requests = extractMetricValue(from: metricValues["AD_REQUESTS"])
        
        // Calculate eCPM manually from earnings and impressions
        let eCPM = calculateECPM(earnings: earnings, impressions: impressions)
        
        return AdUnitData(
            adUnitName: adUnitName,
            adUnitId: adUnitId,
            adUnitFormat: adUnitFormat,
            adType: adType,
            earnings: earnings,
            impressions: impressions,
            clicks: clicks,
            ctr: ctr,
            eCPM: eCPM,
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
    
    private static func calculateECPM(earnings: String, impressions: String) -> String {
        guard let earningsValue = Double(earnings),
              let impressionsValue = Double(impressions),
              impressionsValue > 0 else {
            return "0"
        }
        
        // eCPM = (Earnings / Impressions) * 1000
        let eCPM = (earningsValue / impressionsValue) * 1000
        return String(eCPM)
    }
    
    enum CodingKeys: String, CodingKey {
        case adUnitName
        case adUnitId
        case adUnitFormat
        case adType
        case earnings
        case impressions
        case clicks
        case ctr
        case eCPM
        case requests
    }
    
    // Method to get value for specific filter
    func getValue(for filter: AdUnitMetricFilter, isDemoMode: Bool = false) -> String {
        switch filter {
        case .earnings:
            return formattedEarnings(isDemoMode: isDemoMode)
        case .clicks:
            return clicks
        case .impressions:
            return impressions
        case .requests:
            return requests
        case .eCPM:
            return formattedECPM(isDemoMode: isDemoMode)
        }
    }
} 