import Foundation

enum DateFilter: String, CaseIterable {
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