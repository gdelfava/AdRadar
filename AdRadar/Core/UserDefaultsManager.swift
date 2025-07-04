import Foundation

/// Manages UserDefaults with proper app group handling and error recovery
class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let appGroupID = "group.com.delteqis.AdRadar"
    private var sharedDefaults: UserDefaults?
    private var standardDefaults: UserDefaults
    private var useSharedContainer: Bool = false
    
    private init() {
        self.standardDefaults = UserDefaults.standard
        
        // Initialize shared UserDefaults with enhanced error handling
        self.initializeSharedContainer()
    }
    
    private func initializeSharedContainer() {
        // Check if we're running in an extension or main app
        let isExtension = Bundle.main.bundlePath.hasSuffix(".appex")
        
        // Try to initialize shared container only if we have proper entitlements
        do {
            if let shared = UserDefaults(suiteName: appGroupID) {
                // Test write/read to ensure it's working properly
                let testKey = "__test_container_access__"
                let testValue = "test_\(Date().timeIntervalSince1970)"
                
                shared.set(testValue, forKey: testKey)
                shared.synchronize()
                
                if shared.string(forKey: testKey) == testValue {
                    self.sharedDefaults = shared
                    self.useSharedContainer = true
                    shared.removeObject(forKey: testKey) // Clean up test
                    shared.synchronize()
                    print("[UserDefaultsManager] Successfully initialized shared UserDefaults for \(isExtension ? "extension" : "main app")")
                } else {
                    throw NSError(domain: "UserDefaultsManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Container test failed"])
                }
            } else {
                throw NSError(domain: "UserDefaultsManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create shared suite"])
            }
        } catch {
            print("[UserDefaultsManager] Warning: Shared container unavailable (\(error.localizedDescription)), using standard UserDefaults")
            self.sharedDefaults = nil
            self.useSharedContainer = false
        }
    }
    
    // MARK: - Safe Container Access
    
    private func safeDefaults() -> UserDefaults {
        if useSharedContainer, let shared = sharedDefaults {
            return shared
        }
        return standardDefaults
    }
    
    // MARK: - Async Synchronization
    
    /// Performs synchronization on background queue to avoid blocking main thread
    private func asyncSync() {
        guard useSharedContainer else { return }
        
        Task.detached(priority: .utility) {
            self.safeDefaults().synchronize()
        }
    }
    
    // MARK: - Shared Container Methods
    
    func setValue(_ value: Any?, forKey key: String) {
        let defaults = safeDefaults()
        defaults.set(value, forKey: key)
        
        // Use async synchronization to prevent blocking
        asyncSync()
    }
    
    func getValue(forKey key: String) -> Any? {
        return safeDefaults().object(forKey: key)
    }
    
    func removeValue(forKey key: String) {
        let defaults = safeDefaults()
        defaults.removeObject(forKey: key)
        
        // Use async synchronization to prevent blocking
        asyncSync()
    }
    
    // MARK: - Type-Specific Methods
    
    func setString(_ value: String?, forKey key: String) {
        setValue(value, forKey: key)
    }
    
    func getString(forKey key: String) -> String? {
        return getValue(forKey: key) as? String
    }
    
    func setData(_ value: Data?, forKey key: String) {
        setValue(value, forKey: key)
    }
    
    func getData(forKey key: String) -> Data? {
        return getValue(forKey: key) as? Data
    }
    
    func setDate(_ value: Date?, forKey key: String) {
        setValue(value, forKey: key)
    }
    
    func getDate(forKey key: String) -> Date? {
        return getValue(forKey: key) as? Date
    }
    
    func setBool(_ value: Bool, forKey key: String) {
        setValue(value, forKey: key)
    }
    
    func getBool(forKey key: String) -> Bool {
        return getValue(forKey: key) as? Bool ?? false
    }
    
    // MARK: - Summary Data Methods
    
    func saveSummaryData(_ summary: AdSenseSummaryData) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let encoded = try encoder.encode(summary)
            setData(encoded, forKey: "summaryData")
            setDate(Date(), forKey: "summaryLastUpdate")
            print("[UserDefaultsManager] Successfully saved summary data using \(useSharedContainer ? "shared" : "standard") container")
        } catch {
            print("[UserDefaultsManager] Failed to encode summary data: \(error.localizedDescription)")
        }
    }
    
    func loadSummaryData() -> AdSenseSummaryData? {
        guard let data = getData(forKey: "summaryData") else {
            print("[UserDefaultsManager] No summary data found in \(useSharedContainer ? "shared" : "standard") container")
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let summary = try decoder.decode(AdSenseSummaryData.self, from: data)
            print("[UserDefaultsManager] Successfully loaded summary data")
            return summary
        } catch {
            print("[UserDefaultsManager] Failed to decode summary data: \(error.localizedDescription)")
            // Clean up corrupted data
            removeValue(forKey: "summaryData")
            return nil
        }
    }
    
    func getLastUpdateDate() -> Date? {
        return getDate(forKey: "summaryLastUpdate")
    }
    
    // MARK: - Health Check
    
    func isSharedContainerAvailable() -> Bool {
        return useSharedContainer && sharedDefaults != nil
    }
    
    func getContainerStatus() -> String {
        if useSharedContainer {
            return "Using shared App Group container: \(appGroupID)"
        } else {
            return "Using standard UserDefaults (shared container unavailable)"
        }
    }
    
    func resetSharedContainer() {
        print("[UserDefaultsManager] Resetting shared container...")
        initializeSharedContainer()
    }
    
    // MARK: - Debug Information
    
    #if DEBUG
    func debugInfo() -> String {
        let containerStatus = getContainerStatus()
        let memoryUsage = MemoryManager.shared.getCurrentMemoryStatus()
        return """
        UserDefaults Status: \(containerStatus)
        Memory Usage: \(memoryUsage)
        Last Update: \(getLastUpdateDate()?.formatted() ?? "Never")
        """
    }
    #endif
} 