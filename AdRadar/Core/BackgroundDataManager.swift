import Foundation
import BackgroundTasks
import UIKit
import WidgetKit

/// Manages background data fetching and synchronization across iOS app, widget, and watch app
@MainActor
class BackgroundDataManager: NSObject, ObservableObject {
    static let shared = BackgroundDataManager()
    
    // Background task identifiers - must match Info.plist
    private let refreshTaskIdentifier = "com.delteqis.AdRadar.refresh"
    private let processingTaskIdentifier = "com.delteqis.AdRadar.processing"
    
    // Refresh intervals and timeouts
    private let backgroundRefreshInterval: TimeInterval = 15 * 60 // 15 minutes
    private let appActiveRefreshInterval: TimeInterval = 5 * 60   // 5 minutes
    private let taskTimeout: TimeInterval = 25 // 25 seconds timeout
    
    @Published var isBackgroundRefreshEnabled = false
    @Published var lastBackgroundUpdate: Date?
    @Published var backgroundTasksScheduled = 0
    @Published var isPerformingBackgroundTask = false
    
    private var backgroundTaskCompletionHandler: (() -> Void)?
    private var activeTimeoutWorkItems: [DispatchWorkItem] = []
    
    private override init() {
        super.init()
        setupBackgroundTasks()
        checkBackgroundRefreshStatus()
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        // Use nonisolated cleanup for deinit
        nonisolatedCleanup()
    }
    
    // MARK: - Setup and Monitoring
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillTerminate(_:)),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning(_:)),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private nonisolated func handleAppWillTerminate(_ notification: Notification) {
        print("[BackgroundDataManager] App will terminate - performing cleanup")
        nonisolatedCleanup()
    }
    
    @objc private nonisolated func handleMemoryWarning(_ notification: Notification) {
        print("[BackgroundDataManager] Received memory warning - cleaning up")
        Task { @MainActor in
            MemoryManager.shared.performMaintenanceCleanup()
        }
    }
    
    // MARK: - Cleanup Methods
    
    /// Synchronous cleanup that can be called from isolated contexts
    private func isolatedCleanup() {
        print("[BackgroundDataManager] Performing isolated cleanup")
        activeTimeoutWorkItems.forEach { $0.cancel() }
        activeTimeoutWorkItems.removeAll()
        MemoryManager.shared.aggressiveCleanup()
    }
    
    /// Synchronous cleanup that can be called from nonisolated contexts
    private nonisolated func nonisolatedCleanup() {
        print("[BackgroundDataManager] Performing nonisolated cleanup")
        // Cancel timeout items synchronously
        DispatchQueue.main.sync {
            BackgroundDataManager.shared.activeTimeoutWorkItems.forEach { $0.cancel() }
            BackgroundDataManager.shared.activeTimeoutWorkItems.removeAll()
        }
        // Perform memory cleanup
        MemoryManager.shared.aggressiveCleanup()
    }
    
    private func cancelAllTimeouts() {
        activeTimeoutWorkItems.forEach { $0.cancel() }
        activeTimeoutWorkItems.removeAll()
    }
    
    // MARK: - Task Management
    
    private func createTimeoutWorkItem(for task: BGTask, name: String) -> DispatchWorkItem {
        let timeoutWork = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                print("[BackgroundDataManager] ⚠️ \(name) timeout - forcing completion")
                task.setTaskCompleted(success: false)
                self?.isPerformingBackgroundTask = false
                self?.isolatedCleanup()
            }
        }
        
        activeTimeoutWorkItems.append(timeoutWork)
        return timeoutWork
    }
    
    private func cleanupAfterTask() {
        isolatedCleanup()
        isPerformingBackgroundTask = false
    }
    
    // MARK: - Public Interface
    
    /// Initialize background data manager - call from App.swift
    func initialize() {
        scheduleBackgroundTasks()
        print("[BackgroundDataManager] Initialized with background refresh: \(isBackgroundRefreshEnabled)")
    }
    
    /// Perform immediate data refresh and update all targets
    func performDataRefresh() async -> Bool {
        print("[BackgroundDataManager] Starting immediate data refresh...")
        
        // Perform memory cleanup before starting
        MemoryManager.shared.performMaintenanceCleanup()
        
        defer {
            // Ensure cleanup after completion
            MemoryManager.shared.aggressiveCleanup()
        }
        
        // Check network connectivity
        let isConnected = await withCheckedContinuation { continuation in
            Task.detached {
                continuation.resume(returning: NetworkMonitor.shared.isConnected)
            }
        }
        
        guard isConnected else {
            print("[BackgroundDataManager] No network connection available")
            return false
        }
        
        // Get auth credentials
        guard let accessToken = UserDefaultsManager.shared.getString(forKey: "accessToken"),
              let accountID = UserDefaultsManager.shared.getString(forKey: "adSenseAccountID") else {
            print("[BackgroundDataManager] Missing auth credentials")
            return false
        }
        
        // Fetch fresh data from both APIs
        let success = await fetchAndUpdateData(accessToken: accessToken, accountID: accountID)
        
        if success {
            lastBackgroundUpdate = Date()
            UserDefaultsManager.shared.setDate(Date(), forKey: "lastBackgroundUpdate")
            
            // Update all targets
            await updateAllTargets()
        }
        
        return success
    }
    
    /// Handle app becoming active - perform refresh if needed
    func handleAppBecomeActive() {
        Task {
            let shouldRefresh = await shouldPerformActiveRefresh()
            if shouldRefresh {
                print("[BackgroundDataManager] App became active - performing refresh")
                let _ = await performDataRefresh()
            }
        }
    }
    
    /// Handle app entering background - schedule background tasks
    func handleAppEnterBackground() {
        scheduleBackgroundTasks()
        print("[BackgroundDataManager] App entered background - tasks scheduled")
    }
    
    // MARK: - Background Task Setup
    
    private func setupBackgroundTasks() {
        // Register background app refresh task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskIdentifier, using: nil) { [weak self] task in
            print("[BackgroundDataManager] Background refresh task triggered")
            self?.handleBackgroundRefreshTask(task as! BGAppRefreshTask)
        }
        
        // Register background processing task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: processingTaskIdentifier, using: nil) { [weak self] task in
            print("[BackgroundDataManager] Background processing task triggered")
            self?.handleBackgroundProcessingTask(task as! BGProcessingTask)
        }
    }
    
    private func scheduleBackgroundTasks() {
        // Cancel existing tasks
        BGTaskScheduler.shared.cancelAllTaskRequests()
        backgroundTasksScheduled = 0
        
        guard isBackgroundRefreshEnabled else {
            print("[BackgroundDataManager] Background refresh disabled - not scheduling tasks")
            return
        }
        
        // Schedule background app refresh
        let refreshRequest = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)
        refreshRequest.earliestBeginDate = Date(timeIntervalSinceNow: backgroundRefreshInterval)
        
        do {
            try BGTaskScheduler.shared.submit(refreshRequest)
            backgroundTasksScheduled += 1
            print("[BackgroundDataManager] Scheduled background refresh task")
        } catch {
            print("[BackgroundDataManager] Failed to schedule refresh task: \(error)")
        }
        
        // Schedule background processing task
        let processingRequest = BGProcessingTaskRequest(identifier: processingTaskIdentifier)
        processingRequest.earliestBeginDate = Date(timeIntervalSinceNow: backgroundRefreshInterval * 2)
        processingRequest.requiresNetworkConnectivity = true
        processingRequest.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(processingRequest)
            backgroundTasksScheduled += 1
            print("[BackgroundDataManager] Scheduled background processing task")
        } catch {
            print("[BackgroundDataManager] Failed to schedule processing task: \(error)")
        }
    }
    
    // MARK: - Background Task Handlers
    
    private func handleBackgroundRefreshTask(_ task: BGAppRefreshTask) {
        print("[BackgroundDataManager] Executing background refresh task")
        guard !isPerformingBackgroundTask else {
            print("[BackgroundDataManager] Another task is in progress - skipping")
            task.setTaskCompleted(success: false)
            return
        }
        
        isPerformingBackgroundTask = true
        
        // Create timeout handler
        let timeoutWork = createTimeoutWorkItem(for: task, name: "Background refresh")
        DispatchQueue.main.asyncAfter(deadline: .now() + taskTimeout, execute: timeoutWork)
        
        // Schedule next refresh
        scheduleBackgroundTasks()
        
        // Set expiration handler
        task.expirationHandler = { [weak self] in
            print("[BackgroundDataManager] Background refresh task expired")
            task.setTaskCompleted(success: false)
            self?.cleanupAfterTask()
        }
        
        // Perform refresh with error handling
        Task {
            do {
                try Task.checkCancellation()
                
                // Perform memory cleanup before starting
                MemoryManager.shared.performMaintenanceCleanup()
                
                let success = await performDataRefresh()
                
                if !timeoutWork.isCancelled {
                    timeoutWork.cancel()
                    task.setTaskCompleted(success: success)
                    print("[BackgroundDataManager] Background refresh completed: \(success)")
                }
            } catch {
                print("[BackgroundDataManager] Background refresh failed: \(error)")
                task.setTaskCompleted(success: false)
            }
            
            cleanupAfterTask()
        }
    }
    
    private func handleBackgroundProcessingTask(_ task: BGProcessingTask) {
        print("[BackgroundDataManager] Executing background processing task")
        guard !isPerformingBackgroundTask else {
            print("[BackgroundDataManager] Another task is in progress - skipping")
            task.setTaskCompleted(success: false)
            return
        }
        
        isPerformingBackgroundTask = true
        
        // Create timeout handler
        let timeoutWork = createTimeoutWorkItem(for: task, name: "Background processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + taskTimeout, execute: timeoutWork)
        
        // Schedule next processing
        scheduleBackgroundTasks()
        
        // Set expiration handler
        task.expirationHandler = { [weak self] in
            print("[BackgroundDataManager] Background processing task expired")
            task.setTaskCompleted(success: false)
            self?.cleanupAfterTask()
        }
        
        // Perform processing with error handling
        Task {
            do {
                try Task.checkCancellation()
                
                // Perform memory cleanup before starting
                MemoryManager.shared.performMaintenanceCleanup()
                
                let success = await performComprehensiveDataUpdate()
                
                if !timeoutWork.isCancelled {
                    timeoutWork.cancel()
                    task.setTaskCompleted(success: success)
                    print("[BackgroundDataManager] Background processing completed: \(success)")
                }
            } catch {
                print("[BackgroundDataManager] Background processing failed: \(error)")
                task.setTaskCompleted(success: false)
            }
            
            cleanupAfterTask()
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchAndUpdateData(accessToken: String, accountID: String) async -> Bool {
        // Calculate date range for API calls
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        // Fetch AdSense data
        let adSenseResult = await AdSenseAPI.shared.fetchSummaryData(
            accountID: accountID,
            accessToken: accessToken,
            startDate: startDate,
            endDate: endDate
        )
        
        switch adSenseResult {
        case .success(let summaryData):
            // Convert to shared data model
            let sharedData = SharedSummaryData(from: summaryData)
            
            // Save to both legacy and new shared containers
            UserDefaultsManager.shared.saveSummaryData(summaryData)
            CrossPlatformDataBridge.shared.saveSharedSummaryData(sharedData)
            
            print("[BackgroundDataManager] Successfully updated AdSense data")
            return true
            
        case .failure(let error):
            print("[BackgroundDataManager] AdSense fetch failed: \(error)")
            return false
        }
    }
    
    private func performComprehensiveDataUpdate() async -> Bool {
        print("[BackgroundDataManager] Starting comprehensive data update...")
        
        // Perform regular data refresh
        let basicSuccess = await performDataRefresh()
        
        if basicSuccess {
            // Perform additional tasks like data cleanup, analytics, etc.
            performMaintenanceTasks()
        }
        
        return basicSuccess
    }
    
    // MARK: - Target Updates
    
    private func updateAllTargets() async {
        print("[BackgroundDataManager] Updating all targets...")
        
        // Update widget
        updateWidget()
        
        // Update watch app
        updateWatchApp()
        
        // Trigger UI refresh in main app if active
        refreshMainAppUI()
    }
    
    private func updateWidget() {
        print("[BackgroundDataManager] Reloading widget timelines...")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func updateWatchApp() {
        // Load fresh data from shared container
        guard let sharedData = CrossPlatformDataBridge.shared.loadSharedSummaryData() else {
            print("[BackgroundDataManager] No shared data to send to watch")
            return
        }
        
        // Send to watch via WatchDataSyncService
        WatchDataSyncService.shared.sendSummaryData(sharedData)
    }
    
    private func refreshMainAppUI() {
        // Post notification to refresh UI if app is active
        NotificationCenter.default.post(name: .backgroundDataUpdated, object: nil)
        print("[BackgroundDataManager] Posted UI refresh notification")
    }
    
    // MARK: - Utility Methods
    
    private func checkBackgroundRefreshStatus() {
        isBackgroundRefreshEnabled = UIApplication.shared.backgroundRefreshStatus == .available
        
        if let lastUpdate = UserDefaultsManager.shared.getDate(forKey: "lastBackgroundUpdate") {
            lastBackgroundUpdate = lastUpdate
        }
    }
    
    private func shouldPerformActiveRefresh() async -> Bool {
        // Check if enough time has passed since last refresh
        if let lastUpdate = lastBackgroundUpdate {
            let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
            if timeSinceLastUpdate < appActiveRefreshInterval {
                print("[BackgroundDataManager] Too soon for active refresh (last update: \(Int(timeSinceLastUpdate))s ago)")
                return false
            }
        }
        
        // Check memory status before refresh
        let memoryStatus = MemoryManager.shared.getCurrentMemoryStatus()
        print("[BackgroundDataManager] Memory status before refresh: \(memoryStatus)")
        
        // If memory usage is high, perform cleanup first
        if MemoryManager.shared.getCurrentMemoryUsage() > 150 * 1024 * 1024 {
            print("[BackgroundDataManager] High memory usage - performing cleanup before refresh")
            MemoryManager.shared.performMaintenanceCleanup()
        }
        
        return true
    }
    
    private func performMaintenanceTasks() {
        print("[BackgroundDataManager] Performing maintenance tasks...")
        
        // Clean up old cached data
        cleanupOldData()
        
        // Check memory usage
        let memoryPressure = MemoryManager.shared.checkMemoryPressure()
        if memoryPressure {
            print("[BackgroundDataManager] Memory cleanup performed during background update")
        }
    }
    
    private func cleanupOldData() {
        // Remove data older than 30 days (placeholder for future cleanup logic)
        let _ = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // Add cleanup logic here if needed for cached historical data
        print("[BackgroundDataManager] Data cleanup completed")
    }
    
    // MARK: - Debug Information
    
    #if DEBUG
    func getDebugInfo() -> String {
        return """
        Background Data Manager Status:
        - Background Refresh: \(isBackgroundRefreshEnabled ? "Enabled" : "Disabled")
        - Last Update: \(lastBackgroundUpdate?.formatted() ?? "Never")
        - Scheduled Tasks: \(backgroundTasksScheduled)
        - System Background Status: \(UIApplication.shared.backgroundRefreshStatus.rawValue)
        """
    }
    
    /// Force background task execution for testing
    func simulateBackgroundTask() {
        Task {
            print("[BackgroundDataManager] Simulating background task...")
            let success = await performDataRefresh()
            print("[BackgroundDataManager] Simulated task result: \(success)")
        }
    }
    #endif
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let backgroundDataUpdated = Notification.Name("backgroundDataUpdated")
} 