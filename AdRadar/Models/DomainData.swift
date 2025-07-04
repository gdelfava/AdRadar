import Foundation

struct DomainData: Identifiable, Codable, Equatable {
    let id = UUID()
    let domainName: String
    let earnings: String
    let requests: String
    let pageViews: String
    let impressions: String
    let clicks: String
    let ctr: String
    let rpm: String
    
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
    
    enum CodingKeys: String, CodingKey {
        case domainName = "DOMAIN_NAME"
        case earnings = "ESTIMATED_EARNINGS"
        case requests = "AD_REQUESTS"
        case pageViews = "PAGE_VIEWS"
        case impressions = "IMPRESSIONS"
        case clicks = "CLICKS"
        case ctr = "IMPRESSIONS_CTR"
        case rpm = "IMPRESSIONS_RPM"
    }
} 