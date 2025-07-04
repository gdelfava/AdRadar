import Foundation

/// Shared data models for cross-platform communication
/// These models are used across iOS app, widget, and watch app

// MARK: - Shared Summary Data
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
    
    init(from adSenseData: AdSenseSummaryData) {
        self.todayEarnings = adSenseData.today
        self.yesterdayEarnings = adSenseData.yesterday
        self.last7DaysEarnings = adSenseData.last7Days
        self.thisMonthEarnings = adSenseData.thisMonth
        self.lastMonthEarnings = adSenseData.lastMonth
        self.lifetimeEarnings = adSenseData.lifetime
        
        self.todayDelta = adSenseData.todayDelta
        self.todayDeltaPositive = adSenseData.todayDeltaPositive
        self.yesterdayDelta = adSenseData.yesterdayDelta
        self.yesterdayDeltaPositive = adSenseData.yesterdayDeltaPositive
        self.last7DaysDelta = adSenseData.last7DaysDelta
        self.last7DaysDeltaPositive = adSenseData.last7DaysDeltaPositive
        self.thisMonthDelta = adSenseData.thisMonthDelta
        self.thisMonthDeltaPositive = adSenseData.thisMonthDeltaPositive
        self.lastMonthDelta = adSenseData.lastMonthDelta
        self.lastMonthDeltaPositive = adSenseData.lastMonthDeltaPositive
        
        // Default metrics (can be enhanced later)
        self.todayClicks = nil
        self.todayPageViews = nil
        self.todayImpressions = nil
        
        self.lastUpdated = Date()
        self.dataVersion = 1
    }
    
    // Empty initializer for default/error states
    init() {
        self.todayEarnings = "R 0.00"
        self.yesterdayEarnings = "R 0.00"
        self.last7DaysEarnings = "R 0.00"
        self.thisMonthEarnings = "R 0.00"
        self.lastMonthEarnings = "R 0.00"
        self.lifetimeEarnings = "R 0.00"
        
        self.todayDelta = nil
        self.todayDeltaPositive = nil
        self.yesterdayDelta = nil
        self.yesterdayDeltaPositive = nil
        self.last7DaysDelta = nil
        self.last7DaysDeltaPositive = nil
        self.thisMonthDelta = nil
        self.thisMonthDeltaPositive = nil
        self.lastMonthDelta = nil
        self.lastMonthDeltaPositive = nil
        
        self.todayClicks = nil
        self.todayPageViews = nil
        self.todayImpressions = nil
        
        self.lastUpdated = Date()
        self.dataVersion = 1
    }
}

// MARK: - Background Task Status
struct BackgroundTaskStatus: Codable {
    let isEnabled: Bool
    let lastSuccessfulUpdate: Date?
    let consecutiveFailures: Int
    let nextScheduledUpdate: Date?
    let totalBackgroundExecutions: Int
    
    init() {
        self.isEnabled = false
        self.lastSuccessfulUpdate = nil
        self.consecutiveFailures = 0
        self.nextScheduledUpdate = nil
        self.totalBackgroundExecutions = 0
    }
}

// MARK: - Data Freshness Info
struct DataFreshnessInfo: Codable {
    let lastUpdate: Date
    let dataAge: TimeInterval
    let isStale: Bool
    let source: DataSource
    
    var ageDescription: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .hour, .day]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 1
        return formatter.string(from: dataAge) ?? "Unknown"
    }
    
    init(lastUpdate: Date, source: DataSource = .background) {
        self.lastUpdate = lastUpdate
        self.dataAge = Date().timeIntervalSince(lastUpdate)
        self.isStale = dataAge > 30 * 60 // Consider stale after 30 minutes
        self.source = source
    }
}

enum DataSource: String, Codable {
    case background = "background"
    case userRefresh = "user_refresh"
    case appLaunch = "app_launch"
    case cached = "cached"
}

// MARK: - Shared Constants
enum SharedConstants {
    static let appGroupID = "group.com.delteqis.AdRadar"
    static let sharedSummaryDataKey = "shared_summary_data"
    static let backgroundTaskStatusKey = "background_task_status"
    static let dataFreshnessKey = "data_freshness_info"
    
    // Background task identifiers
    static let backgroundRefreshTaskID = "com.delteqis.AdRadar.refresh"
    static let backgroundProcessingTaskID = "com.delteqis.AdRadar.processing"
    
    // Refresh intervals
    static let backgroundRefreshInterval: TimeInterval = 15 * 60  // 15 minutes
    static let appActiveRefreshInterval: TimeInterval = 5 * 60   // 5 minutes
    static let widgetRefreshInterval: TimeInterval = 10 * 60     // 10 minutes
}

// MARK: - Shared Data Manager Protocol
protocol SharedDataManagerProtocol {
    func saveSharedData(_ data: SharedSummaryData)
    func loadSharedData() -> SharedSummaryData?
    func getDataFreshness() -> DataFreshnessInfo?
    func updateBackgroundTaskStatus(_ status: BackgroundTaskStatus)
    func getBackgroundTaskStatus() -> BackgroundTaskStatus?
}

// MARK: - Cross-Platform Data Bridge
class CrossPlatformDataBridge {
    static let shared = CrossPlatformDataBridge()
    
    private let appGroupDefaults: UserDefaults?
    
    private init() {
        self.appGroupDefaults = UserDefaults(suiteName: SharedConstants.appGroupID)
    }
    
    // MARK: - Data Persistence
    
    func saveSharedSummaryData(_ data: SharedSummaryData) {
        do {
            let encoded = try JSONEncoder().encode(data)
            appGroupDefaults?.set(encoded, forKey: SharedConstants.sharedSummaryDataKey)
            
            // Update freshness info
            let freshness = DataFreshnessInfo(lastUpdate: data.lastUpdated)
            saveDataFreshness(freshness)
            
            print("[CrossPlatformDataBridge] Saved shared summary data")
        } catch {
            print("[CrossPlatformDataBridge] Failed to encode summary data: \(error)")
        }
    }
    
    func loadSharedSummaryData() -> SharedSummaryData? {
        guard let data = appGroupDefaults?.data(forKey: SharedConstants.sharedSummaryDataKey) else {
            print("[CrossPlatformDataBridge] No shared summary data found")
            return nil
        }
        
        do {
            let decoded = try JSONDecoder().decode(SharedSummaryData.self, from: data)
            print("[CrossPlatformDataBridge] Loaded shared summary data")
            return decoded
        } catch {
            print("[CrossPlatformDataBridge] Failed to decode summary data: \(error)")
            return nil
        }
    }
    
    private func saveDataFreshness(_ freshness: DataFreshnessInfo) {
        do {
            let encoded = try JSONEncoder().encode(freshness)
            appGroupDefaults?.set(encoded, forKey: SharedConstants.dataFreshnessKey)
        } catch {
            print("[CrossPlatformDataBridge] Failed to save freshness info: \(error)")
        }
    }
    
    func getDataFreshness() -> DataFreshnessInfo? {
        guard let data = appGroupDefaults?.data(forKey: SharedConstants.dataFreshnessKey) else {
            return nil
        }
        
        return try? JSONDecoder().decode(DataFreshnessInfo.self, from: data)
    }
    
    func saveBackgroundTaskStatus(_ status: BackgroundTaskStatus) {
        do {
            let encoded = try JSONEncoder().encode(status)
            appGroupDefaults?.set(encoded, forKey: SharedConstants.backgroundTaskStatusKey)
        } catch {
            print("[CrossPlatformDataBridge] Failed to save background task status: \(error)")
        }
    }
    
    func getBackgroundTaskStatus() -> BackgroundTaskStatus? {
        guard let data = appGroupDefaults?.data(forKey: SharedConstants.backgroundTaskStatusKey) else {
            return BackgroundTaskStatus() // Return default status
        }
        
        return try? JSONDecoder().decode(BackgroundTaskStatus.self, from: data)
    }
    
    // MARK: - Data Validation
    
    func isDataValid(_ data: SharedSummaryData?) -> Bool {
        guard let data = data else { return false }
        
        // Check if data is not too old
        let ageThreshold: TimeInterval = 60 * 60 // 1 hour
        let dataAge = Date().timeIntervalSince(data.lastUpdated)
        
        return dataAge < ageThreshold
    }
    
    func shouldRefreshData() -> Bool {
        guard let freshness = getDataFreshness() else { return true }
        return freshness.isStale
    }
    
    // MARK: - Cleanup
    
    func clearAllSharedData() {
        appGroupDefaults?.removeObject(forKey: SharedConstants.sharedSummaryDataKey)
        appGroupDefaults?.removeObject(forKey: SharedConstants.dataFreshnessKey)
        appGroupDefaults?.removeObject(forKey: SharedConstants.backgroundTaskStatusKey)
        print("[CrossPlatformDataBridge] Cleared all shared data")
    }
} 