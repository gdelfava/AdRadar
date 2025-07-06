import Foundation
import Combine
import Network
import GoogleSignIn
import SwiftUI

enum MetricsCardType {
    case today, yesterday, last7Days, thisMonth, lastMonth, lastThreeYears
}

@MainActor
class SummaryViewModel: ObservableObject {
    @Published var summaryData: AdSenseSummaryData? = nil
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var isOffline: Bool = false
    @Published var showOfflineToast: Bool = false
    @Published var showNetworkErrorModal: Bool = false
    @Published var hasLoaded: Bool = false
    @Published var selectedDay: Date? = nil
    @Published var selectedDayMetrics: AdSenseDayMetrics? = nil
    @Published var showDayMetricsSheet: Bool = false
    @Published var errorMessage: String? = nil
    @Published var lastUpdateTime: Date? = nil
    @Published var selectedCardTitle: String = ""
    @Published var showEmptyState: Bool = false
    @Published var emptyStateMessage: String = ""
    
    var accessToken: String?
    @MainActor private var accountID: String?
    var authViewModel: AuthViewModel?
    private var fetchTask: Task<Void, Never>?
    private var metricsTask: Task<Void, Never>?
    
    // Remove redundant data storage
    private var cachedData: [MetricsCardType: AdSenseSummaryData] = [:]
    
    init(accessToken: String?, authViewModel: AuthViewModel? = nil) {
        self.accessToken = accessToken
        self.authViewModel = authViewModel
        // Remove synchronous UserDefaults access from init - defer to async methods
        // This prevents blocking the main thread during view initialization
        Task {
            await loadLastUpdateTime()
        }
    }
    
    deinit {
        fetchTask?.cancel()
        metricsTask?.cancel()
        // Clear cached data
        cachedData.removeAll()
    }
    
    // Add method to clear cached data
    func clearCache() {
        cachedData.removeAll()
    }
    
    // Add method to get data for a specific card type
    func getData(for card: MetricsCardType) -> AdSenseSummaryData? {
        return cachedData[card]
    }
    
    // Add method to set data for a specific card type
    func setData(_ data: AdSenseSummaryData, for card: MetricsCardType) {
        cachedData[card] = data
    }
    
    private func formatCurrency(_ value: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "R "
        formatter.currencyGroupingSeparator = " "
        formatter.currencyDecimalSeparator = ","
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        if let doubleValue = Double(value.replacingOccurrences(of: ",", with: ".")) {
            return formatter.string(from: NSNumber(value: doubleValue)) ?? "R 0,00"
        }
        return "R 0,00"
    }

    private func calculateDelta(current: String, previous: String) -> (String, Bool)? {
        guard let currentValue = Double(current.replacingOccurrences(of: ",", with: ".")),
              let previousValue = Double(previous.replacingOccurrences(of: ",", with: ".")),
              previousValue != 0 else { return nil }
        
        // Calculate currency difference
        let diff = currentValue - previousValue
        let isPositive = diff >= 0
        
        // Format currency difference
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "R "
        formatter.currencyGroupingSeparator = " "
        formatter.currencyDecimalSeparator = ","
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let formattedDiff = formatter.string(from: NSNumber(value: abs(diff))) ?? "R 0,00"
        
        // Calculate and format percentage
        let percent = ((currentValue - previousValue) / abs(previousValue)) * 100
        let formattedPercent = String(format: "%+.1f%%", percent)
        
        // Combine both values
        let sign = isPositive ? "+" : "-"
        let combined = "\(sign)\(formattedDiff) (\(formattedPercent))"
        
        return (combined, isPositive)
    }
    
    private func sleep(seconds: Double) async {
        let duration = UInt64(seconds * 1_000_000_000)
        try? await Task.sleep(nanoseconds: duration)
    }
    
    func fetchSummary() async {
        fetchTask?.cancel()
        fetchTask = Task {
            if !NetworkMonitor.shared.isConnected {
                self.isOffline = true
                self.showOfflineToast = true
                self.showNetworkErrorModal = true
                // Auto-hide after 2 seconds
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    self.showOfflineToast = false
                }
                self.showEmptyState = true
                self.emptyStateMessage = "Unable to load data. Please check your connection."
                self.error = nil
                self.isLoading = false
                return
            } else {
                self.isOffline = false
                self.showNetworkErrorModal = false
            }

            // If in demo mode, use demo data
            if let authVM = authViewModel, authVM.isDemoMode {
                self.summaryData = DemoDataProvider.shared.summaryData
                self.isLoading = false
                self.error = nil
                return
            }

            let maxRetries = 3
            var retryCount = 0
            var currentToken = accessToken ?? ""

            while retryCount < maxRetries {
                self.isLoading = true
                self.error = nil
                
                // Fetch account ID
                let accountResult = await AdSenseAPI.fetchAccountID(accessToken: currentToken)
                switch accountResult {
                case .success(let accountID):
                    self.accountID = accountID
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
                        self.emptyStateMessage = "Please sign in to view your earnings data"
                        self.error = nil
                        self.isLoading = false
                        return
                    case .requestFailed(_):
                        self.showEmptyState = true
                        self.emptyStateMessage = "Unable to load earnings data. Please try again later."
                        self.error = nil
                        self.isLoading = false
                        return
                    case .noAccountID:
                        self.showEmptyState = true
                        self.emptyStateMessage = "No AdSense account found"
                        self.error = nil
                        self.isLoading = false
                        return
                    case .invalidURL, .invalidResponse, .decodingError:
                        self.showEmptyState = true
                        self.emptyStateMessage = "Unable to load earnings data. Please try again later."
                        self.error = nil
                        self.isLoading = false
                        return
                    }
                }
                
                guard let accountID = self.accountID else {
                    self.error = "No AdSense account found."
                    self.isLoading = false
                    return
                }
                
                let calendar = Calendar.current
                let today = Date()
                let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
                let last7DaysStart = calendar.date(byAdding: .day, value: -6, to: today)!
                let prev7DaysStart = calendar.date(byAdding: .day, value: -13, to: today)!
                let prev7DaysEnd = calendar.date(byAdding: .day, value: -7, to: today)!
                let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
                let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
                let lastMonthEnd = calendar.date(byAdding: .day, value: -1, to: thisMonthStart)!
                let prevMonthStart = calendar.date(byAdding: .month, value: -1, to: lastMonthStart)!
                let prevMonthEnd = calendar.date(byAdding: .day, value: -1, to: lastMonthStart)!
                let threeYearsAgo = calendar.date(byAdding: .year, value: -3, to: today)!
                
                // Create a local copy of the token for concurrent operations
                let token = currentToken
                
                // Fetch all summary data in parallel using the local token copy
                async let todayResult = AdSenseAPI.shared.fetchSummaryData(accountID: accountID, accessToken: token, startDate: today, endDate: today)
                async let yesterdayResult = AdSenseAPI.shared.fetchSummaryData(accountID: accountID, accessToken: token, startDate: yesterday, endDate: yesterday)
                async let last7DaysResult = AdSenseAPI.shared.fetchSummaryData(accountID: accountID, accessToken: token, startDate: last7DaysStart, endDate: today)
                async let prev7DaysResult = AdSenseAPI.shared.fetchSummaryData(accountID: accountID, accessToken: token, startDate: prev7DaysStart, endDate: prev7DaysEnd)
                async let thisMonthResult = AdSenseAPI.shared.fetchSummaryData(accountID: accountID, accessToken: token, startDate: thisMonthStart, endDate: today)
                async let lastMonthResult = AdSenseAPI.shared.fetchSummaryData(accountID: accountID, accessToken: token, startDate: lastMonthStart, endDate: lastMonthEnd)
                async let prevMonthResult = AdSenseAPI.shared.fetchSummaryData(accountID: accountID, accessToken: token, startDate: prevMonthStart, endDate: prevMonthEnd)
                async let lastThreeYearsResult = AdSenseAPI.shared.fetchSummaryData(accountID: accountID, accessToken: token, startDate: threeYearsAgo, endDate: today)
                
                let (todayData, yesterdayData, last7DaysData, prev7DaysData, thisMonthData, lastMonthData, prevMonthData, lastThreeYearsData) = await (
                    todayResult, yesterdayResult, last7DaysResult, prev7DaysResult, thisMonthResult, lastMonthResult, prevMonthResult, lastThreeYearsResult
                )
                // Format and calculate deltas
                let todayValue = (try? todayData.get().last7Days) ?? "0.00"
                let yesterdayValue = (try? yesterdayData.get().last7Days) ?? "0.00"
                let last7Value = (try? last7DaysData.get().last7Days) ?? "0.00"
                let prev7Value = (try? prev7DaysData.get().last7Days) ?? "0.00"
                let thisMonthValue = (try? thisMonthData.get().last7Days) ?? "0.00"
                let lastMonthValue = (try? lastMonthData.get().last7Days) ?? "0.00"
                let prevMonthValue = (try? prevMonthData.get().last7Days) ?? "0.00"
                let lastThreeYearsValue = (try? lastThreeYearsData.get().last7Days) ?? "0.00"
                let summary = AdSenseSummaryData(
                    today: formatCurrency(todayValue),
                    yesterday: formatCurrency(yesterdayValue),
                    last7Days: formatCurrency(last7Value),
                    thisMonth: formatCurrency(thisMonthValue),
                    lastMonth: formatCurrency(lastMonthValue),
                    lifetime: formatCurrency(lastThreeYearsValue),
                    todayDelta: calculateDelta(current: todayValue, previous: yesterdayValue)?.0,
                    todayDeltaPositive: calculateDelta(current: todayValue, previous: yesterdayValue)?.1,
                    yesterdayDelta: calculateDelta(current: yesterdayValue, previous: (try? yesterdayData.get().last7Days) ?? "0.00")?.0, // Could use last week's same day if available
                    yesterdayDeltaPositive: calculateDelta(current: yesterdayValue, previous: (try? yesterdayData.get().last7Days) ?? "0.00")?.1,
                    last7DaysDelta: calculateDelta(current: last7Value, previous: prev7Value)?.0,
                    last7DaysDeltaPositive: calculateDelta(current: last7Value, previous: prev7Value)?.1,
                    thisMonthDelta: calculateDelta(current: thisMonthValue, previous: lastMonthValue)?.0,
                    thisMonthDeltaPositive: calculateDelta(current: thisMonthValue, previous: lastMonthValue)?.1,
                    lastMonthDelta: calculateDelta(current: lastMonthValue, previous: prevMonthValue)?.0,
                    lastMonthDeltaPositive: calculateDelta(current: lastMonthValue, previous: prevMonthValue)?.1
                )
                self.summaryData = summary
                AdSenseAPI.shared.saveSummaryToSharedContainer(summary)
                // Save the last update time using UserDefaultsManager
                let now = Date()
                UserDefaultsManager.shared.setDate(now, forKey: "summaryLastUpdate")
                self.lastUpdateTime = now
                self.hasLoaded = true
                self.isLoading = false
                
                // Send data to Apple Watch
                Task {
                    // Try to get today's detailed metrics to send with summary
                    let todayMetricsResult = await AdSenseAPI.shared.fetchMetricsForRange(
                        accountID: accountID, 
                        accessToken: token, 
                        startDate: today, 
                        endDate: today
                    )
                    
                    let todayMetrics: AdSenseDayMetrics? = try? todayMetricsResult.get()
                    
                    // Convert to SharedSummaryData format using the from: initializer
                    let sharedData = SharedSummaryData(from: summary)
                    
                    WatchDataSyncService.shared.sendSummaryData(sharedData, todayMetrics: todayMetrics)
                }
                return
            }
            self.showEmptyState = true
            self.emptyStateMessage = "Unable to load earnings data. Please try again later."
            self.error = nil
            self.isLoading = false
        }
    }
    
    /// Fetches and stores detailed metrics for a given card type (date range)
    func fetchMetrics(forCard cardType: MetricsCardType) async {
        // If in demo mode, use demo data
        if let authVM = authViewModel, authVM.isDemoMode {
            self.selectedDayMetrics = DemoDataProvider.shared.dayMetrics
            self.selectedCardTitle = cardType.title
            self.showDayMetricsSheet = true
            return
        }
        
        // Cancel any existing task
        metricsTask?.cancel()
        
        // Create new task
        metricsTask = Task {
            await performFetchMetrics(forCard: cardType)
        }
        
        await metricsTask?.value
    }
    
    private func performFetchMetrics(forCard cardType: MetricsCardType) async {
        print("[SummaryViewModel] Starting fetchMetrics for card: \(cardType)")
        errorMessage = nil
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            print("[SummaryViewModel] No current user found")
            self.showEmptyState = true
            self.emptyStateMessage = "Please sign in to view your earnings data"
            self.error = nil
            return
        }
        
        // Capture accountID before the closure
        let localAccountID = accountID ?? ""
        
        // Set the card title based on the card type
        switch cardType {
        case .today:
            selectedCardTitle = "Today so far"
        case .yesterday:
            selectedCardTitle = "Yesterday"
        case .last7Days:
            selectedCardTitle = "Last 7 Days"
        case .thisMonth:
            selectedCardTitle = "This month"
        case .lastMonth:
            selectedCardTitle = "Last month"
        case .lastThreeYears:
            selectedCardTitle = "Last Three Years"
        }
        
        print("[SummaryViewModel] Found current user, refreshing tokens...")
        await withCheckedContinuation { continuation in
            user.refreshTokensIfNeeded { [weak self] refreshedUser, error in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                if let error = error {
                    print("[SummaryViewModel] Token refresh failed: \(error)")
                    DispatchQueue.main.async {
                        self.showEmptyState = true
                        self.emptyStateMessage = "Please sign in to view your earnings data"
                        self.error = nil
                        continuation.resume()
                    }
                    return
                }
                guard let refreshedUser = refreshedUser else {
                    print("[SummaryViewModel] No user after token refresh")
                    DispatchQueue.main.async {
                        self.showEmptyState = true
                        self.emptyStateMessage = "Please sign in to view your earnings data"
                        self.error = nil
                        continuation.resume()
                    }
                    return
                }
                print("[SummaryViewModel] Successfully refreshed tokens")
                let accessToken = refreshedUser.accessToken.tokenString
                print("[SummaryViewModel] Using accountID: \(localAccountID)")
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let startDate: Date
                let endDate: Date
                switch cardType {
                case .today:
                    startDate = today
                    endDate = today
                case .yesterday:
                    startDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
                    endDate = startDate
                case .last7Days:
                    startDate = calendar.date(byAdding: .day, value: -6, to: today) ?? today
                    endDate = today
                case .thisMonth:
                    let comps = calendar.dateComponents([.year, .month], from: today)
                    startDate = calendar.date(from: comps) ?? today
                    endDate = today
                case .lastMonth:
                    let comps = calendar.dateComponents([.year, .month], from: today)
                    let firstOfThisMonth = calendar.date(from: comps) ?? today
                    let lastDayOfLastMonth = calendar.date(byAdding: .day, value: -1, to: firstOfThisMonth) ?? today
                    let compsLastMonth = calendar.dateComponents([.year, .month], from: lastDayOfLastMonth)
                    startDate = calendar.date(from: compsLastMonth) ?? today
                    endDate = lastDayOfLastMonth
                case .lastThreeYears:
                    startDate = calendar.date(byAdding: .year, value: -3, to: today) ?? today
                    endDate = today
                }
                
                // Create a new task and store it in a local variable first
                let newTask = Task {
                    let result = await AdSenseAPI.shared.fetchMetricsForRange(accountID: localAccountID, accessToken: accessToken, startDate: startDate, endDate: endDate)
                    // Check if task was cancelled
                    if Task.isCancelled {
                        continuation.resume()
                        return
                    }
                    await MainActor.run {
                        switch result {
                        case .success(let metrics):
                            self.selectedDayMetrics = metrics
                            self.showDayMetricsSheet = true
                        case .failure(_):
                            self.showEmptyState = true
                            self.emptyStateMessage = "Unable to load earnings data. Please try again later."
                            self.error = nil
                        }
                        continuation.resume()
                    }
                }
                
                // Assign the task on the main actor
                Task { @MainActor in
                    self.metricsTask = newTask
                }
            }
        }
    }
    
    // MARK: - Async Initialization Methods
    
    /// Loads the last update time asynchronously to avoid blocking main thread during init
    private func loadLastUpdateTime() async {
        // Perform UserDefaults access on background queue
        let lastUpdate = await Task.detached {
            UserDefaultsManager.shared.getLastUpdateDate()
        }.value
        
        await MainActor.run {
            self.lastUpdateTime = lastUpdate
        }
    }
}

// Add extension to make MetricsCardType conform to CaseIterable
extension MetricsCardType: CaseIterable {
    static var allCases: [MetricsCardType] {
        [.today, .yesterday, .last7Days, .thisMonth, .lastMonth, .lastThreeYears]
    }
}

// MARK: - MetricsCardType Extension
extension MetricsCardType {
    var title: String {
        switch self {
        case .today:
            return "Today so far"
        case .yesterday:
            return "Yesterday"
        case .last7Days:
            return "Last 7 Days"
        case .thisMonth:
            return "This Month"
        case .lastMonth:
            return "Last Month"
        case .lastThreeYears:
            return "Last Three Years"
        }
    }
} 
