import Foundation

struct CountryData: Identifiable, Codable, Equatable {
    let id = UUID()
    let countryCode: String
    let countryName: String
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
    
    var displayCountryName: String {
        // Convert country code to readable name
        let locale = Locale(identifier: "en_US")
        return locale.localizedString(forRegionCode: countryCode) ?? countryCode
    }
    
    var flagEmoji: String {
        // Convert country code to flag emoji
        let base: UInt32 = 127397
        var flag = ""
        for scalar in countryCode.unicodeScalars {
            flag.unicodeScalars.append(UnicodeScalar(base + scalar.value)!)
        }
        return flag
    }
    
    enum CodingKeys: String, CodingKey {
        case countryCode = "COUNTRY_CODE"
        case countryName = "COUNTRY_NAME"
        case earnings = "ESTIMATED_EARNINGS"
        case requests = "AD_REQUESTS"
        case pageViews = "PAGE_VIEWS"
        case impressions = "IMPRESSIONS"
        case clicks = "CLICKS"
        case ctr = "IMPRESSIONS_CTR"
        case rpm = "IMPRESSIONS_RPM"
    }
} 