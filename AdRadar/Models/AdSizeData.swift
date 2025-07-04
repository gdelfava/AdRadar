import Foundation

struct AdSizeData: Identifiable, Codable, Equatable {
    let id = UUID()
    let adSize: String
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
        case adSize = "AD_UNIT_NAME"
        case earnings = "ESTIMATED_EARNINGS"
        case requests = "AD_REQUESTS"
        case pageViews = "PAGE_VIEWS"
        case impressions = "IMPRESSIONS"
        case clicks = "CLICKS"
        case ctr = "IMPRESSIONS_CTR"
        case rpm = "IMPRESSIONS_RPM"
    }
}

enum AdSizeDateFilter: String, CaseIterable {
    case today = "Today"
    case yesterday = "Yesterday"
    case last7Days = "Last 7 Days"
    case thisMonth = "This Month"
    case lastMonth = "Last Month"
    case lifetime = "Lifetime"
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = Date()
        
        switch self {
        case .today:
            return (today, today)
        case .yesterday:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            return (yesterday, yesterday)
        case .last7Days:
            let start = calendar.date(byAdding: .day, value: -6, to: today)!
            return (start, today)
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
            return (start, today)
        case .lastMonth:
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
            let start = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
            let end = calendar.date(byAdding: .day, value: -1, to: thisMonthStart)!
            return (start, end)
        case .lifetime:
            let threeYearsAgo = calendar.date(byAdding: .year, value: -3, to: today)!
            return (threeYearsAgo, today)
        }
    }
} 