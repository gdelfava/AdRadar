import Foundation
import WatchConnectivity

@MainActor
class WatchDataSyncService: NSObject, ObservableObject {
    static let shared = WatchDataSyncService()
    private var connectionRetryCount = 0
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 2.0
    @Published private(set) var connectionState: WCSessionActivationState = .notActivated
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    private func checkConnectionState() -> Bool {
        guard WCSession.isSupported() else {
            print("📱 [iOS] WatchConnectivity not supported")
            return false
        }
        
        let session = WCSession.default
        guard session.activationState == .activated else {
            print("📱 [iOS] Session not activated, current state: \(session.activationState.rawValue)")
            retryConnection()
            return false
        }
        
        // Also check network connectivity
        guard NetworkMonitor.shared.shouldProceedWithRequest() else {
            print("📱 [iOS] Network connection unavailable")
            return false
        }
        
        return true
    }
    
    private func retryConnection(attempts: Int = 3, delay: TimeInterval = 2.0) {
        guard attempts > 0 else {
            print("📱 [iOS] Max retry attempts reached")
            return
        }
        
        print("📱 [iOS] Retrying connection... Attempts remaining: \(attempts)")
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // Check network state before retrying
            guard NetworkMonitor.shared.shouldProceedWithRequest() else {
                print("📱 [iOS] Network unavailable, waiting before retry")
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                // Retry with same attempt count since this was a network issue
                retryConnection(attempts: attempts, delay: delay)
                return
            }
            
            if WCSession.default.activationState != .activated {
                setupWatchConnectivity()
                retryConnection(attempts: attempts - 1, delay: delay)
            }
        }
    }
    
    // Send summary data to watch
    func sendSummaryData(_ summaryData: SharedSummaryData, todayMetrics: AdSenseDayMetrics? = nil) {
        print("📱 [iOS] Attempting to send data to watch...")
        
        guard checkConnectionState() else {
            print("📱 [iOS] Connection check failed - will retry automatically")
            return
        }
        
        print("📱 [iOS] Session state: \(WCSession.default.activationState.rawValue)")
        print("📱 [iOS] Session reachable: \(WCSession.default.isReachable)")
        print("📱 [iOS] Watch app installed: \(WCSession.default.isWatchAppInstalled)")
        
        // Check if watch app is installed
        guard WCSession.default.isWatchAppInstalled else {
            print("📱 [iOS] Watch app not installed - skipping data sync")
            print("📱 [iOS] To install: Open Watch app on iPhone → My Watch → App Store → Install AdRadar")
            return
        }
        
        // Log connection status
        if !WCSession.default.isReachable {
            print("📱 [iOS] Watch not reachable but trying updateApplicationContext for background sync")
        }
        
        // Create dictionary with summary and metrics data
        var watchContext: [String: Any] = [
            "todayEarnings": summaryData.todayEarnings,
            "yesterdayEarnings": summaryData.yesterdayEarnings,
            "last7DaysEarnings": summaryData.last7DaysEarnings,
            "thisMonthEarnings": summaryData.thisMonthEarnings,
            "lastMonthEarnings": summaryData.lastMonthEarnings,
            "lastUpdated": summaryData.lastUpdated.timeIntervalSince1970,
            "dataVersion": summaryData.dataVersion
        ]
        
        // Add delta information
        if let todayDelta = summaryData.todayDelta {
            watchContext["todayDelta"] = todayDelta
            watchContext["todayDeltaPositive"] = summaryData.todayDeltaPositive ?? false
        }
        if let yesterdayDelta = summaryData.yesterdayDelta {
            watchContext["yesterdayDelta"] = yesterdayDelta
            watchContext["yesterdayDeltaPositive"] = summaryData.yesterdayDeltaPositive ?? false
        }
        if let last7DaysDelta = summaryData.last7DaysDelta {
            watchContext["last7DaysDelta"] = last7DaysDelta
            watchContext["last7DaysDeltaPositive"] = summaryData.last7DaysDeltaPositive ?? false
        }
        if let thisMonthDelta = summaryData.thisMonthDelta {
            watchContext["thisMonthDelta"] = thisMonthDelta
            watchContext["thisMonthDeltaPositive"] = summaryData.thisMonthDeltaPositive ?? false
        }
        if let lastMonthDelta = summaryData.lastMonthDelta {
            watchContext["lastMonthDelta"] = lastMonthDelta
            watchContext["lastMonthDeltaPositive"] = summaryData.lastMonthDeltaPositive ?? false
        }
        
        // Add today's metrics if available
        if let metrics = todayMetrics {
            watchContext["todayClicks"] = metrics.clicks
            watchContext["todayPageViews"] = metrics.pageViews
            watchContext["todayImpressions"] = metrics.impressions
        } else if let clicks = summaryData.todayClicks {
            watchContext["todayClicks"] = clicks
            watchContext["todayPageViews"] = summaryData.todayPageViews
            watchContext["todayImpressions"] = summaryData.todayImpressions
        }
        
        do {
            try WCSession.default.updateApplicationContext(watchContext)
            print("📱 [iOS] Successfully sent data to watch via updateApplicationContext")
            connectionRetryCount = 0 // Reset retry count on success
        } catch {
            print("📱 [iOS] Failed to send data to watch: \(error)")
            handleSendError()
        }
    }
    
    private func handleSendError() {
        connectionRetryCount += 1
        if connectionRetryCount < maxRetryAttempts {
            print("📱 [iOS] Retrying connection... Attempt \(connectionRetryCount) of \(maxRetryAttempts)")
            retryConnection()
        } else {
            print("📱 [iOS] Max retry attempts reached. Please check watch connectivity.")
            connectionRetryCount = 0
        }
    }
    
    // Send a simple status update
    func sendQuickUpdate(earnings: String, lastUpdated: Date) {
        guard checkConnectionState() else {
            print("Watch session not available")
            return
        }
        
        guard WCSession.default.isReachable else {
            print("Watch is not reachable")
            return
        }
        
        let quickData: [String: Any] = [
            "quickUpdate": true,
            "earnings": earnings,
            "lastUpdated": lastUpdated.timeIntervalSince1970
        ]
        
        do {
            try WCSession.default.updateApplicationContext(quickData)
            print("Successfully sent quick update to watch")
            connectionRetryCount = 0 // Reset retry count on success
        } catch {
            print("Failed to send quick update to watch: \(error)")
            handleSendError()
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchDataSyncService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("📱 [iOS] WC Session activation failed with error: \(error.localizedDescription)")
            return
        }
        print("📱 [iOS] WC Session activated with state: \(activationState.rawValue)")
        print("📱 [iOS] Watch app installed: \(session.isWatchAppInstalled)")
        print("📱 [iOS] Session reachable: \(session.isReachable)")
        
        if !session.isWatchAppInstalled {
            print("📱 [iOS] ⚠️  WATCH APP NOT INSTALLED")
            print("📱 [iOS] 📲 To install the watch app:")
            print("📱 [iOS] 1. Open the Watch app on your iPhone")
            print("📱 [iOS] 2. Go to 'My Watch' tab")
            print("📱 [iOS] 3. Scroll down to 'Available Apps'")
            print("📱 [iOS] 4. Find 'AdRadar' and tap 'Install'")
            print("📱 [iOS] 5. Wait for installation to complete")
        } else {
            print("📱 [iOS] ✅ Watch app is installed and ready")
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        print("WC Session did become inactive")
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        print("📱 [iOS] WC Session did deactivate")
        // Reactivate the session
        session.activate()
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("📱 [iOS] Received message from watch with reply handler: \(message)")
        
        if let action = message["action"] as? String, action == "requestUpdate" {
            print("📱 [iOS] Watch requested data update - responding via reply handler")
            
            Task { @MainActor in
                // Try to load real data from shared container first
                if let sharedData = CrossPlatformDataBridge.shared.loadSharedSummaryData() {
                    print("📱 [iOS] Sending real data from shared container to watch")
                    
                    let realContext: [String: Any] = [
                        "todayEarnings": sharedData.todayEarnings,
                        "yesterdayEarnings": sharedData.yesterdayEarnings,
                        "last7DaysEarnings": sharedData.last7DaysEarnings,
                        "thisMonthEarnings": sharedData.thisMonthEarnings,
                        "lastMonthEarnings": sharedData.lastMonthEarnings,
                        "todayDelta": sharedData.todayDelta as Any? ?? NSNull(),
                        "todayDeltaPositive": sharedData.todayDeltaPositive ?? false,
                        "yesterdayDelta": sharedData.yesterdayDelta as Any? ?? NSNull(),
                        "yesterdayDeltaPositive": sharedData.yesterdayDeltaPositive ?? false,
                        "last7DaysDelta": sharedData.last7DaysDelta as Any? ?? NSNull(),
                        "last7DaysDeltaPositive": sharedData.last7DaysDeltaPositive ?? false,
                        "thisMonthDelta": sharedData.thisMonthDelta as Any? ?? NSNull(),
                        "thisMonthDeltaPositive": sharedData.thisMonthDeltaPositive ?? false,
                        "lastMonthDelta": sharedData.lastMonthDelta as Any? ?? NSNull(),
                        "lastMonthDeltaPositive": sharedData.lastMonthDeltaPositive ?? false,
                        "todayClicks": sharedData.todayClicks as Any? ?? NSNull(),
                        "todayPageViews": sharedData.todayPageViews as Any? ?? NSNull(),
                        "todayImpressions": sharedData.todayImpressions as Any? ?? NSNull(),
                        "lastUpdated": sharedData.lastUpdated.timeIntervalSince1970,
                        "status": "success"
                    ]
                    
                    replyHandler(realContext)
                    print("📱 [iOS] ✅ Sent real data to watch via reply handler")
                    
                } else if let legacyData = UserDefaultsManager.shared.loadSummaryData() {
                    print("📱 [iOS] Sending real data from legacy storage to watch")
                    
                    let legacyContext: [String: Any] = [
                        "todayEarnings": legacyData.today,
                        "yesterdayEarnings": legacyData.yesterday,
                        "last7DaysEarnings": legacyData.last7Days,
                        "thisMonthEarnings": legacyData.thisMonth,
                        "lastMonthEarnings": legacyData.lastMonth,
                        "todayDelta": legacyData.todayDelta as Any? ?? NSNull(),
                        "todayDeltaPositive": legacyData.todayDeltaPositive ?? false,
                        "yesterdayDelta": legacyData.yesterdayDelta as Any? ?? NSNull(),
                        "yesterdayDeltaPositive": legacyData.yesterdayDeltaPositive ?? false,
                        "last7DaysDelta": legacyData.last7DaysDelta as Any? ?? NSNull(),
                        "last7DaysDeltaPositive": legacyData.last7DaysDeltaPositive ?? false,
                        "thisMonthDelta": legacyData.thisMonthDelta as Any? ?? NSNull(),
                        "thisMonthDeltaPositive": legacyData.thisMonthDeltaPositive ?? false,
                        "lastMonthDelta": legacyData.lastMonthDelta as Any? ?? NSNull(),
                        "lastMonthDeltaPositive": legacyData.lastMonthDeltaPositive ?? false,
                        "lastUpdated": Date().timeIntervalSince1970,
                        "status": "success"
                    ]
                    
                    replyHandler(legacyContext)
                    print("📱 [iOS] ✅ Sent legacy data to watch via reply handler")
                    
                } else {
                    print("📱 [iOS] ⚠️ No data available - sending fallback response")
                    
                    // Send a fallback response indicating no data
                    let fallbackContext: [String: Any] = [
                        "status": "no_data",
                        "message": "No data available on iPhone",
                        "lastUpdated": Date().timeIntervalSince1970
                    ]
                    
                    replyHandler(fallbackContext)
                }
            }
        } else {
            // Send a basic acknowledgment if no specific action
            replyHandler(["status": "received", "timestamp": Date().timeIntervalSince1970])
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("📱 [iOS] Received message from watch (no reply handler): \(message)")
        // Handle messages that don't expect a reply
    }
} 
