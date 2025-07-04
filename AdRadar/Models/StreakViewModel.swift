import Foundation
import SwiftUI

struct StreakDayData: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let earnings: Double
    let clicks: Int
    let impressions: Int
    let impressionCTR: Double
    let pageViews: Int
    let costPerClick: Double
    let requests: Int
    let delta: Double?
    let deltaPositive: Bool?
    
    // Trend properties
    var earningsTrend: Double? {
        guard let delta = delta else { return nil }
        return deltaPositive == true ? abs(delta) : -abs(delta)
    }
    
    var clicksTrend: Double? {
        // Calculate trend as percentage change from previous day
        guard let delta = delta else { return nil }
        return clicks > 0 ? (delta / Double(clicks)) * 100 : nil
    }
    
    var impressionsTrend: Double? {
        // Calculate trend as percentage change from previous day
        guard let delta = delta else { return nil }
        return impressions > 0 ? (delta / Double(impressions)) * 100 : nil
    }
    
    var ctrTrend: Double? {
        // Calculate trend as percentage change from previous day
        guard let delta = delta else { return nil }
        return impressionCTR > 0 ? (delta / impressionCTR) * 100 : nil
    }
    
    static func == (lhs: StreakDayData, rhs: StreakDayData) -> Bool {
        return lhs.id == rhs.id
    }
}

@MainActor
class StreakViewModel: ObservableObject {
    @Published var streakData: [StreakDayData] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var hasLoaded: Bool = false
    @Published var lastUpdateTime: Date? = nil
    @Published var showEmptyState: Bool = false
    @Published var emptyStateMessage: String? = nil
    
    var accessToken: String?
    private var accountID: String?
    var authViewModel: AuthViewModel?
    private var fetchTask: Task<Void, Never>?
    
    init(accessToken: String?, authViewModel: AuthViewModel? = nil) {
        self.accessToken = accessToken
        self.authViewModel = authViewModel
        // Remove automatic fetching - only fetch when explicitly called
    }
    
    deinit {
        fetchTask?.cancel()
    }
    
    func fetchStreakData() async {
        // If in demo mode, use demo data
        if let authVM = authViewModel, authVM.isDemoMode {
            self.streakData = DemoDataProvider.shared.streakData
            self.lastUpdateTime = Date()
            self.isLoading = false
            self.hasLoaded = true
            return
        }
        
        // Cancel any existing task
        fetchTask?.cancel()
        
        // Create new task
        fetchTask = Task {
            await performFetchStreakData()
        }
        
        await fetchTask?.value
    }
    
    private func performFetchStreakData() async {
        guard let token = accessToken else { return }
        isLoading = true
        error = nil
        showEmptyState = false
        emptyStateMessage = nil
        
        // Fetch account ID with retry logic
        var retryCount = 0
        let maxRetries = 3
        var currentToken = token
        
        while retryCount < maxRetries {
            do {
                try Task.checkCancellation()
                
                let accountResult = await AdSenseAPI.fetchAccountID(accessToken: currentToken)
                switch accountResult {
                case .success(let accountID):
                    self.accountID = accountID
                    break
                case .failure(let err):
                    switch err {
                    case .unauthorized:
                        if let authVM = authViewModel {
                            let refreshed = await authVM.refreshTokenIfNeeded()
                            if refreshed {
                                currentToken = authVM.accessToken ?? currentToken
                                retryCount += 1
                                continue
                            }
                        }
                        self.showEmptyState = true
                        self.emptyStateMessage = "Please sign in again to continue viewing your streak data."
                        self.error = nil
                        self.isLoading = false
                        return
                    case .requestFailed(let message):
                        if message.contains("cancelled") {
                            return // Task was cancelled, exit gracefully
                        }
                        // Instead of showing error, show empty state
                        if retryCount >= maxRetries - 1 {
                            self.showEmptyState = true
                            self.emptyStateMessage = "Unable to connect to AdSense. Please check your connection and try again."
                            self.error = nil
                            self.isLoading = false
                            return
                        }
                        retryCount += 1
                        continue
                    default:
                        self.showEmptyState = true
                        self.emptyStateMessage = "Unable to access your AdSense account. Please try again later."
                        self.error = nil
                        self.isLoading = false
                        return
                    }
                }
                
                guard let accountID = self.accountID else {
                    self.showEmptyState = true
                    self.emptyStateMessage = "No AdSense account found. Please ensure you have an active AdSense account."
                    self.error = nil
                    self.isLoading = false
                    return
                }
                
                // Calculate date range for last 7 days
                let calendar = Calendar.current
                let today = Date()
                let startDate = calendar.date(byAdding: .day, value: -6, to: today)!
                
                // Fetch metrics for each day
                var newStreakData: [StreakDayData] = []
                var previousEarnings: Double?
                
                for dayOffset in 0...6 {
                    try Task.checkCancellation()
                    
                    let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate)!
                    let result = await AdSenseAPI.shared.fetchMetricsForRange(
                        accountID: accountID,
                        accessToken: currentToken,
                        startDate: currentDate,
                        endDate: currentDate
                    )
                    
                    switch result {
                    case .success(let metrics):
                        let earnings = Double(metrics.estimatedEarnings) ?? 0
                        let clicks = Int(metrics.clicks) ?? 0
                        let impressions = Int(metrics.impressions) ?? 0
                        let impressionCTR = Double(metrics.impressionsCTR) ?? 0
                        let pageViews = Int(metrics.pageViews) ?? 0
                        let costPerClick = Double(metrics.costPerClick) ?? 0
                        let requests = Int(metrics.requests) ?? 0
                        
                        // Calculate delta if we have previous earnings
                        var delta: Double?
                        var deltaPositive: Bool?
                        if let prevEarnings = previousEarnings {
                            delta = earnings - prevEarnings
                            deltaPositive = delta! >= 0
                        }
                        
                        let dayData = StreakDayData(
                            date: currentDate,
                            earnings: earnings,
                            clicks: clicks,
                            impressions: impressions,
                            impressionCTR: impressionCTR,
                            pageViews: pageViews,
                            costPerClick: costPerClick,
                            requests: requests,
                            delta: delta,
                            deltaPositive: deltaPositive
                        )
                        
                        newStreakData.append(dayData)
                        previousEarnings = earnings
                        
                    case .failure(let error):
                        if error.localizedDescription.contains("cancelled") {
                            return // Task was cancelled, exit gracefully
                        }
                        // Check for specific empty state conditions
                        if case .requestFailed(let message) = error,
                           message.contains("NEEDS_ATTENTION|") {
                            let actualMessage = String(message.dropFirst("NEEDS_ATTENTION|".count))
                            self.showEmptyState = true
                            self.emptyStateMessage = actualMessage
                            self.error = nil
                            self.isLoading = false
                            return
                        }
                        // Show empty state for any other API errors instead of error message
                        self.showEmptyState = true
                        self.emptyStateMessage = "Unable to load streak data at this time. Please check your connection and try again."
                        self.error = nil
                        self.isLoading = false
                        return
                    }
                }
                
                self.streakData = newStreakData.sorted { $0.date > $1.date }
                self.lastUpdateTime = Date()
                self.isLoading = false
                self.hasLoaded = true
                return
                
            } catch {
                if error is CancellationError {
                    return // Task was cancelled, exit gracefully
                }
                // Show empty state instead of error for unexpected errors
                if retryCount >= maxRetries - 1 {
                    self.showEmptyState = true
                    self.emptyStateMessage = "Unable to load streak data. Please try again later."
                    self.error = nil
                    self.isLoading = false
                    return
                }
                retryCount += 1
            }
        }
        
        self.isLoading = false
    }
    
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        if let authVM = authViewModel, authVM.isDemoMode {
            formatter.currencySymbol = "$"
        } else {
            formatter.locale = Locale.current // Use user's locale for currency
        }
        
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "0.00"
    }
    
    func formatPercentage(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "0%"
    }
    
    func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    // MARK: - Performance Insights Helpers
    
    var bestPerformingDay: StreakDayData? {
        streakData.max(by: { $0.earnings < $1.earnings })
    }
    
    var weeklyTrend: TrendDirection {
        guard streakData.count >= 2 else { return .neutral }
        
        let sortedData = streakData.sorted { $0.date < $1.date }
        let firstHalf = Array(sortedData.prefix(sortedData.count / 2))
        let secondHalf = Array(sortedData.suffix(sortedData.count / 2))
        
        let firstHalfAvg = firstHalf.reduce(0) { $0 + $1.earnings } / Double(firstHalf.count)
        let secondHalfAvg = secondHalf.reduce(0) { $0 + $1.earnings } / Double(secondHalf.count)
        
        let difference = secondHalfAvg - firstHalfAvg
        
        if abs(difference) < 0.01 {
            return .neutral
        } else if difference > 0 {
            return .up
        } else {
            return .down
        }
    }
    
    var performanceConsistency: Double {
        guard !streakData.isEmpty else { return 0.0 }
        
        let earnings = streakData.map { $0.earnings }
        let mean = earnings.reduce(0, +) / Double(earnings.count)
        
        let variance = earnings.reduce(0) { sum, earning in
            sum + pow(earning - mean, 2)
        } / Double(earnings.count)
        
        let standardDeviation = sqrt(variance)
        
        // Calculate coefficient of variation (CV)
        let coefficientOfVariation = mean > 0 ? standardDeviation / mean : 1.0
        
        // Convert to consistency score (lower CV = higher consistency)
        // Cap at 100% and ensure minimum of 0%
        let consistencyScore = max(0.0, min(1.0, 1.0 - coefficientOfVariation))
        
        return consistencyScore
    }
}

enum TrendDirection {
    case up, down, neutral
    
    var icon: String {
        switch self {
        case .up: return "chart.line.uptrend.xyaxis"
        case .down: return "chart.line.downtrend.xyaxis"
        case .neutral: return "chart.line.flattrend.xyaxis"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .neutral: return .orange
        }
    }
    
    var description: String {
        switch self {
        case .up: return "Trending Up"
        case .down: return "Trending Down"
        case .neutral: return "Stable"
        }
    }
} 