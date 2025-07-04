import Foundation
import WatchConnectivity

// MARK: - Shared Data Models (synced with main app)
struct SharedSummaryData: Codable, Equatable {
    let todayEarnings: String
    let yesterdayEarnings: String
    let last7DaysEarnings: String
    let thisMonthEarnings: String
    let lastMonthEarnings: String
    let lifetimeEarnings: String
    
    // Delta information
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
    
    // Metrics data
    let todayClicks: String?
    let todayPageViews: String?
    let todayImpressions: String?
    
    // Metadata
    let lastUpdated: Date
    let dataVersion: Int
}

// MARK: - Legacy Summary Data Model (for backward compatibility)
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

// MARK: - Day Metrics Model
struct AdSenseDayMetrics: Codable {
    let estimatedEarnings: String
    let clicks: String
    let pageViews: String
    let impressions: String
    let adRequests: String
    let matchedAdRequests: String
    let costPerClick: String
    let impressionsCTR: String
    let impressionsRPM: String
    let pageViewsCTR: String
    let pageViewsRPM: String
    
    // For backward compatibility with the UI
    var estimatedGrossRevenue: String { estimatedEarnings }
    var requests: String { pageViews }
    var impressionCTR: String { impressionsCTR }
    var matchedRequests: String { matchedAdRequests }
}

// MARK: - Watch-specific Models
struct WatchSummaryData {
    let todayEarnings: String
    let yesterdayEarnings: String
    let last7DaysEarnings: String
    let thisMonthEarnings: String
    let lastMonthEarnings: String
    
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
    
    let todayClicks: String?
    let todayPageViews: String?
    let todayImpressions: String?
    
    let lastUpdated: Date
    
    // Initialize from WatchConnectivity context (legacy format)
    init(from context: [String: Any]) {
        self.todayEarnings = context["todayEarnings"] as? String ?? "R 0,00"
        self.yesterdayEarnings = context["yesterdayEarnings"] as? String ?? "R 0,00"
        self.last7DaysEarnings = context["last7DaysEarnings"] as? String ?? "R 0,00"
        self.thisMonthEarnings = context["thisMonthEarnings"] as? String ?? "R 0,00"
        self.lastMonthEarnings = context["lastMonthEarnings"] as? String ?? "R 0,00"
        
        self.todayDelta = context["todayDelta"] as? String
        self.todayDeltaPositive = context["todayDeltaPositive"] as? Bool
        self.yesterdayDelta = context["yesterdayDelta"] as? String
        self.yesterdayDeltaPositive = context["yesterdayDeltaPositive"] as? Bool
        self.last7DaysDelta = context["last7DaysDelta"] as? String
        self.last7DaysDeltaPositive = context["last7DaysDeltaPositive"] as? Bool
        self.thisMonthDelta = context["thisMonthDelta"] as? String
        self.thisMonthDeltaPositive = context["thisMonthDeltaPositive"] as? Bool
        self.lastMonthDelta = context["lastMonthDelta"] as? String
        self.lastMonthDeltaPositive = context["lastMonthDeltaPositive"] as? Bool
        
        self.todayClicks = context["todayClicks"] as? String
        self.todayPageViews = context["todayPageViews"] as? String
        self.todayImpressions = context["todayImpressions"] as? String
        
        if let timestamp = context["lastUpdated"] as? TimeInterval {
            self.lastUpdated = Date(timeIntervalSince1970: timestamp)
        } else {
            self.lastUpdated = Date()
        }
    }
    
    // Initialize from SharedSummaryData (new format)
    init(from sharedData: SharedSummaryData) {
        self.todayEarnings = sharedData.todayEarnings
        self.yesterdayEarnings = sharedData.yesterdayEarnings
        self.last7DaysEarnings = sharedData.last7DaysEarnings
        self.thisMonthEarnings = sharedData.thisMonthEarnings
        self.lastMonthEarnings = sharedData.lastMonthEarnings
        
        self.todayDelta = sharedData.todayDelta
        self.todayDeltaPositive = sharedData.todayDeltaPositive
        self.yesterdayDelta = sharedData.yesterdayDelta
        self.yesterdayDeltaPositive = sharedData.yesterdayDeltaPositive
        self.last7DaysDelta = sharedData.last7DaysDelta
        self.last7DaysDeltaPositive = sharedData.last7DaysDeltaPositive
        self.thisMonthDelta = sharedData.thisMonthDelta
        self.thisMonthDeltaPositive = sharedData.thisMonthDeltaPositive
        self.lastMonthDelta = sharedData.lastMonthDelta
        self.lastMonthDeltaPositive = sharedData.lastMonthDeltaPositive
        
        self.todayClicks = sharedData.todayClicks
        self.todayPageViews = sharedData.todayPageViews
        self.todayImpressions = sharedData.todayImpressions
        
        self.lastUpdated = sharedData.lastUpdated
    }
}

// MARK: - Watch Data Bridge
class WatchDataBridge {
    static let shared = WatchDataBridge()
    private let appGroupID = "group.com.delteqis.AdRadar"
    
    private init() {}
    
    /// Load data from shared container (for use when phone is not reachable)
    func loadSharedData() -> WatchSummaryData? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "shared_summary_data") else {
            print("[WatchDataBridge] No shared data found")
            return nil
        }
        
        do {
            let sharedData = try JSONDecoder().decode(SharedSummaryData.self, from: data)
            return WatchSummaryData(from: sharedData)
        } catch {
            print("[WatchDataBridge] Failed to decode shared data: \(error)")
            return nil
        }
    }
    
    /// Check if shared data is available and fresh
    func isSharedDataFresh() -> Bool {
        guard let watchData = loadSharedData() else { return false }
        
        let dataAge = Date().timeIntervalSince(watchData.lastUpdated)
        return dataAge < 30 * 60 // Consider fresh if less than 30 minutes old
    }
} 