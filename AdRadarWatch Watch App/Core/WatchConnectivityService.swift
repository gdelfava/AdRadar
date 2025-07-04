import Foundation
import WatchConnectivity
import SwiftUI

@MainActor
class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()
    
    @Published var summaryData: WatchSummaryData?
    @Published var isConnected: Bool = false
    @Published var lastUpdateTime: Date?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var connectionRetryCount = 0
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 2.0
    private var retryTask: Task<Void, Never>?
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            print("⌚ [Watch] WC Session activation initiated")
        } else {
            print("⌚ [Watch] WC Session not supported")
            self.errorMessage = "Watch connectivity not supported"
        }
    }
    
    private func checkConnectionState() -> Bool {
        guard WCSession.isSupported() else {
            print("⌚ [Watch] WatchConnectivity not supported")
            self.errorMessage = "Watch connectivity not supported"
            return false
        }
        
        let session = WCSession.default
        guard session.activationState == .activated else {
            print("⌚ [Watch] Session not activated, current state: \(session.activationState.rawValue)")
            retryConnection()
            return false
        }
        
        return true
    }
    
    private func retryConnection(attempts: Int = 3, delay: TimeInterval = 2.0) {
        // Cancel any existing retry task
        retryTask?.cancel()
        
        retryTask = Task { @MainActor in
            guard attempts > 0 else {
                print("⌚ [Watch] Max retry attempts reached")
                self.errorMessage = "Connection failed after multiple attempts"
                return
            }
            
            print("⌚ [Watch] Retrying connection... Attempts remaining: \(attempts)")
            
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            if !Task.isCancelled {
                if WCSession.default.activationState != .activated {
                    setupWatchConnectivity()
                    retryConnection(attempts: attempts - 1, delay: delay)
                } else {
                    print("⌚ [Watch] Connection restored")
                    self.errorMessage = nil
                    requestDataFromPhone()
                }
            }
        }
    }
    
    private func handleConnectionError(_ error: Error) {
        connectionRetryCount += 1
        if connectionRetryCount < maxRetryAttempts {
            print("⌚ [Watch] Connection error, retrying... Attempt \(connectionRetryCount) of \(maxRetryAttempts)")
            retryConnection()
        } else {
            print("⌚ [Watch] Max retry attempts reached")
            self.errorMessage = "Unable to connect to iPhone"
            connectionRetryCount = 0
            loadDataFromSharedContainer() // Fallback to shared container
        }
    }
    
    func requestDataFromPhone() {
        print("⌚ [Watch] 📱 Requesting data from iPhone...")
        
        guard checkConnectionState() else {
            print("⌚ [Watch] Connection check failed - will retry automatically")
            return
        }
        
        print("⌚ [Watch] Session state: \(WCSession.default.activationState.rawValue)")
        print("⌚ [Watch] iPhone reachable: \(WCSession.default.isReachable)")
        
        // Always try shared container first for immediate data
        loadDataFromSharedContainer()
        
        // If iPhone is reachable, request fresh data
        if WCSession.default.isReachable {
            let message: [String: Any] = [
                "action": "requestUpdate",
                "timestamp": Date().timeIntervalSince1970
            ]
            
            print("⌚ [Watch] 📤 Sending message to iPhone...")
            WCSession.default.sendMessage(message, replyHandler: { [weak self] reply in
                Task { @MainActor in
                    print("⌚ [Watch] ✅ Received fresh data from iPhone")
                    self?.handleDataUpdate(reply)
                    self?.isLoading = false
                    self?.connectionRetryCount = 0 // Reset retry count on success
                    self?.errorMessage = nil
                }
            }) { [weak self] error in
                Task { @MainActor in
                    print("⌚ [Watch] ❌ Failed to get fresh data: \(error.localizedDescription)")
                    self?.handleConnectionError(error)
                }
            }
        } else {
            print("⌚ [Watch] 📱 iPhone not reachable - using cached data")
            isLoading = false
            
            if summaryData == nil {
                errorMessage = "No data available - check iPhone connection"
                retryConnection() // Attempt to reconnect
            }
        }
    }
    
    private func loadDataFromSharedContainer() {
        if let sharedData = WatchDataBridge.shared.loadSharedData() {
            print("⌚ [Watch] Loaded data from shared container")
            self.summaryData = sharedData
            self.lastUpdateTime = sharedData.lastUpdated
            self.errorMessage = nil
            
            // Check if data is stale
            if !WatchDataBridge.shared.isSharedDataFresh() {
                print("⌚ [Watch] Shared data is stale")
            }
        } else {
            print("⌚ [Watch] No data available in shared container")
            if summaryData == nil {
                errorMessage = "No data available"
            }
        }
    }
    
    private func handleDataUpdate(_ context: [String: Any]) {
        print("⌚ [Watch] 🔄 Processing data update...")
        
        // Check if this is a "no data" response from iOS
        if let status = context["status"] as? String, status == "no_data" {
            print("⌚ [Watch] ⚠️ iPhone reports no data available")
            self.errorMessage = context["message"] as? String ?? "No data available on iPhone"
            return
        }
        
        let newData = WatchSummaryData(from: context)
        
        // Check if this is actually newer data
        if let currentData = self.summaryData {
            let timeDiff = newData.lastUpdated.timeIntervalSince(currentData.lastUpdated)
            if timeDiff <= 0 {
                print("⌚ [Watch] ℹ️ Received data is not newer than current data")
            } else {
                print("⌚ [Watch] ✅ Received newer data (diff: \(Int(timeDiff))s)")
            }
        } else {
            print("⌚ [Watch] ✅ Received initial data")
        }
        
        self.summaryData = newData
        self.lastUpdateTime = newData.lastUpdated
        self.errorMessage = nil
        
        print("⌚ [Watch] 💰 Today's earnings: \(newData.todayEarnings)")
        print("⌚ [Watch] 🕐 Last updated: \(newData.lastUpdated)")
    }
    
    func refreshData() {
        print("⌚ [Watch] 🔄 Manual refresh triggered")
        errorMessage = nil
        isLoading = true
        connectionRetryCount = 0 // Reset retry count on manual refresh
        
        // First, try to request fresh data from iPhone
        requestDataFromPhone()
        
        // Set a timeout fallback to ensure loading state doesn't get stuck
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds timeout
            if self.isLoading {
                print("⌚ [Watch] ⚠️ Refresh timeout - trying shared container fallback")
                self.isLoading = false
                self.loadDataFromSharedContainer()
                
                // If still no data after fallback, show error and retry
                if self.summaryData == nil {
                    self.errorMessage = "Unable to refresh data"
                    self.retryConnection()
                }
            }
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("⌚ [Watch] WC Session activation failed: \(error.localizedDescription)")
                self.errorMessage = "Connection failed"
                return
            }
            
            print("⌚ [Watch] WC Session activated with state: \(activationState.rawValue)")
            print("⌚ [Watch] iPhone reachable: \(session.isReachable)")
            self.isConnected = activationState == .activated
            
            if activationState == .activated {
                // Only request data if iPhone is reachable, otherwise try shared container
                if session.isReachable {
                    self.requestDataFromPhone()
                } else {
                    print("⌚ [Watch] iPhone not reachable on activation, trying shared container...")
                    self.loadDataFromSharedContainer()
                }
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            print("⌚ [Watch] Received application context: \(applicationContext)")
            self.handleDataUpdate(applicationContext)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            print("⌚ [Watch] Received message: \(message)")
            self.handleDataUpdate(message)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            print("⌚ [Watch] Received message with reply handler: \(message)")
            self.handleDataUpdate(message)
            replyHandler(["status": "received"])
        }
    }
} 