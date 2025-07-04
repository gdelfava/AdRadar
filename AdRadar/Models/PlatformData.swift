import Foundation

struct PlatformData: Identifiable, Codable, Equatable {
    let id = UUID()
    let platform: String
    let earnings: String
    let pageViews: String
    let pageRPM: String
    let impressions: String
    let impressionsRPM: String
    let activeViewViewable: String
    let clicks: String
    let requests: String
    let ctr: String
    
    // Computed properties for formatted display
    var formattedEarnings: String {
        guard let value = Double(earnings) else { return earnings }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: value)) ?? earnings
    }
    
    var formattedPageRPM: String {
        guard let value = Double(pageRPM) else { return pageRPM }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: value)) ?? pageRPM
    }
    
    var formattedImpressionsRPM: String {
        guard let value = Double(impressionsRPM) else { return impressionsRPM }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: value)) ?? impressionsRPM
    }
    
    var formattedActiveViewViewable: String {
        guard let value = Double(activeViewViewable) else { return activeViewViewable }
        return String(format: "%.2f%%", value * 100)
    }
    
    var formattedCTR: String {
        guard let value = Double(ctr) else { return ctr }
        return String(format: "%.2f%%", value * 100)
    }
    
    enum CodingKeys: String, CodingKey {
        case platform = "PLATFORM_TYPE"
        case earnings = "ESTIMATED_EARNINGS"
        case pageViews = "PAGE_VIEWS"
        case pageRPM = "PAGE_RPM"
        case impressions = "IMPRESSIONS"
        case impressionsRPM = "IMPRESSIONS_RPM"
        case activeViewViewable = "ACTIVE_VIEW_VIEWABLE"
        case clicks = "CLICKS"
        case requests = "AD_REQUESTS"
        case ctr = "IMPRESSIONS_CTR"
    }
}

enum PlatformDateFilter: String, CaseIterable {
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