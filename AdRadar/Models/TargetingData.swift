import Foundation

struct TargetingData: Identifiable, Codable, Equatable {
    let id = UUID()
    let targetingType: String
    let earnings: String
    let impressions: String
    let clicks: String
    let ctr: String
    let rpm: String
    let requests: String
    let pageViews: String
    
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
    
    // Display name for targeting type
    var displayTargetingType: String {
        switch targetingType.lowercased() {
        case "contextual":
            return "Contextual"
        case "placement":
            return "Placement"
        case "personalized":
            return "Personalized"
        case "run_of_network":
            return "Run of Network"
        case "other":
            return "Other"
        default:
            return targetingType.capitalized
        }
    }
    
    // Icon for targeting type
    var targetingIcon: String {
        switch targetingType.lowercased() {
        case "contextual":
            return "text.alignleft"
        case "placement":
            return "rectangle.3.group"
        case "personalized":
            return "person.circle"
        case "run_of_network":
            return "network"
        case "other":
            return "questionmark.circle"
        default:
            return "target"
        }
    }
    
    // Color for targeting type
    var targetingColor: String {
        switch targetingType.lowercased() {
        case "contextual":
            return "blue"
        case "placement":
            return "green"
        case "personalized":
            return "purple"
        case "run_of_network":
            return "orange"
        case "other":
            return "gray"
        default:
            return "pink"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case targetingType = "TARGETING_TYPE"
        case earnings = "ESTIMATED_EARNINGS"
        case impressions = "IMPRESSIONS"
        case clicks = "CLICKS"
        case ctr = "IMPRESSIONS_CTR"
        case rpm = "IMPRESSIONS_RPM"
        case requests = "AD_REQUESTS"
        case pageViews = "PAGE_VIEWS"
    }
} 