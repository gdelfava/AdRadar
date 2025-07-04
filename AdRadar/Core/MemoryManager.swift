import Foundation
import UIKit
import os.log

/// Manages memory usage and provides utilities for memory optimization
class MemoryManager {
    static let shared = MemoryManager()
    
    private var memoryWarningCount = 0
    private let memoryThreshold: UInt64 = 500 * 1024 * 1024  // 500MB
    private let imageCache = NSCache<NSString, UIImage>()
    private var fontCache: [String: UIFont] = [:]
    private var monitoringTimer: Timer?
    
    private init() {
        setupMemoryPressureMonitoring()
        configureImageCache()
        startMemoryMonitoring()
        #if DEBUG
        print("[MemoryManager] Initialized with threshold: \(ByteCountFormatter().string(fromByteCount: Int64(memoryThreshold)))")
        logInitialMemoryUsage()
        #endif
    }
    
    // MARK: - Image Cache Configuration
    
    private func configureImageCache() {
        // Set reasonable cache limits to prevent memory bloat
        imageCache.countLimit = 50 // Max 50 images
        imageCache.totalCostLimit = 100 * 1024 * 1024 // Max 100MB for images
        
        // Auto-remove images under memory pressure
        imageCache.evictsObjectsWithDiscardedContent = true
    }
    
    // MARK: - Memory Pressure Monitoring
    
    private func setupMemoryPressureMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    /// Checks if the app is under memory pressure and performs cleanup if necessary
    /// - Returns: true if cleanup was performed due to memory pressure, false otherwise
    func checkMemoryPressure() -> Bool {
        let usedMemory = getCurrentMemoryUsage()
        let isUnderPressure = usedMemory > memoryThreshold
        
        if isUnderPressure {
            print("[MemoryManager] ⚠️ Memory pressure detected (\(ByteCountFormatter().string(fromByteCount: Int64(usedMemory)))) - performing cleanup")
            performGradualCleanup()
            return true
        }
        
        return false
    }
    
    @objc private func handleMemoryWarning() {
        print("[MemoryManager] ⚠️ Received memory warning - performing cleanup")
        performGradualCleanup()
    }
    
    // MARK: - Graduated Cache Management
    
    private func lightCleanup() {
        print("[MemoryManager] Performing light cleanup")
        clearImageCache()
        clearFontCache()
        
        #if DEBUG
        let status = getCurrentMemoryStatus()
        print("[MemoryManager] Light cleanup completed - \(status)")
        #endif
    }
    
    func aggressiveCleanup() {
        print("[MemoryManager] Performing aggressive cleanup")
        mediumCleanup()
        // Add any additional aggressive cleanup steps here
        
        #if DEBUG
        let status = getCurrentMemoryStatus()
        print("[MemoryManager] Aggressive cleanup completed - \(status)")
        #endif
    }
    
    // MARK: - Image Management
    
    func optimizedImage(named: String) -> UIImage? {
        let cacheKey = NSString(string: named)
        
        // Check cache first
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Load and optimize image
        guard let originalImage = UIImage(named: named) else { return nil }
        
        // Compress large images
        let optimizedImage = compressImageIfNeeded(originalImage)
        
        // Cache the optimized version
        let cost = Int(optimizedImage.size.width * optimizedImage.size.height * 4) // Estimate bytes
        imageCache.setObject(optimizedImage, forKey: cacheKey, cost: cost)
        
        return optimizedImage
    }
    
    private func compressImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1024
        
        // Check if image is too large
        guard image.size.width > maxDimension || image.size.height > maxDimension else {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = image.size.width / image.size.height
        var newSize: CGSize
        
        if image.size.width > image.size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // Resize image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    // MARK: - Font Management
    
    func optimizedFont(name: String, size: CGFloat) -> UIFont? {
        let cacheKey = "\(name)-\(size)"
        
        if let cachedFont = fontCache[cacheKey] {
            return cachedFont
        }
        
        guard let font = UIFont(name: name, size: size) else {
            return UIFont.systemFont(ofSize: size) // Fallback
        }
        
        // Cache only if we have space
        if fontCache.count < 20 {
            fontCache[cacheKey] = font
        }
        
        return font
    }
    
    // MARK: - Public Cache Management
    
    func performMaintenanceCleanup() {
        // Safe cleanup method for regular maintenance
        lightCleanup()
        
        // Reset warning count after successful maintenance
        if memoryWarningCount > 0 {
            memoryWarningCount = max(0, memoryWarningCount - 1)
        }
    }
    
    func clearImageCache() {
        imageCache.removeAllObjects()
    }
    
    func clearFontCache() {
        fontCache.removeAll()
    }
    
    // MARK: - Memory Usage Monitoring
    
    private func startMemoryMonitoring() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.checkMemoryUsage()
        }
    }
    
    private func checkMemoryUsage() {
        let usedMemory = getCurrentMemoryUsage()
        print("[MemoryManager] Current memory usage: \(ByteCountFormatter().string(fromByteCount: Int64(usedMemory)))")
        
        if usedMemory > memoryThreshold {
            print("[MemoryManager] ⚠️ Memory usage exceeded threshold - performing cleanup")
            performGradualCleanup()
        }
    }
    
    /// Get the current memory usage in bytes
    /// - Returns: Current memory usage in bytes, or 0 if unable to get memory info
    func getCurrentMemoryUsage() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            print("[MemoryManager] Failed to get memory usage info")
            return 0
        }
        
        return info.phys_footprint
    }
    
    /// Get a human-readable string describing the current memory status
    /// - Returns: A string describing the current memory usage as a percentage of the threshold
    func getCurrentMemoryStatus() -> String {
        let usage = getCurrentMemoryUsage()
        let percentage = Double(usage) / Double(memoryThreshold) * 100
        let usageString = ByteCountFormatter().string(fromByteCount: Int64(usage))
        return String(format: "Memory: %.1f%% of threshold (%@)", percentage, usageString)
    }
    
    private func performGradualCleanup() {
        if memoryWarningCount == 0 {
            // First step: Light cleanup
            lightCleanup()
        } else if memoryWarningCount == 1 {
            // Second step: Medium cleanup
            mediumCleanup()
        } else {
            // Final step: Aggressive cleanup
            aggressiveCleanup()
        }
        
        memoryWarningCount += 1
    }
    
    private func mediumCleanup() {
        print("[MemoryManager] Performing medium cleanup")
        lightCleanup()
        URLCache.shared.removeAllCachedResponses()
        
        #if DEBUG
        let status = getCurrentMemoryStatus()
        print("[MemoryManager] Medium cleanup completed - \(status)")
        #endif
    }
    
    private func logInitialMemoryUsage() {
        let usage = getCurrentMemoryUsage()
        print("[MemoryManager] Initial memory usage: \(ByteCountFormatter().string(fromByteCount: Int64(usage)))")
        print("[MemoryManager] Memory threshold: \(ByteCountFormatter().string(fromByteCount: Int64(memoryThreshold)))")
    }
    
    // MARK: - Public Interface Extensions
    
    func prepareForIntensiveTask() {
        print("[MemoryManager] Preparing for intensive task")
        performMaintenanceCleanup()
        
        // Reduce cache limits temporarily
        let originalImageLimit = imageCache.countLimit
        let originalCostLimit = imageCache.totalCostLimit
        
        imageCache.countLimit = max(5, imageCache.countLimit / 2)
        imageCache.totalCostLimit = max(25 * 1024 * 1024, imageCache.totalCostLimit / 2)
        
        // Restore limits after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
            self?.imageCache.countLimit = originalImageLimit
            self?.imageCache.totalCostLimit = originalCostLimit
            print("[MemoryManager] Restored cache limits after intensive task")
        }
    }
    
    // MARK: - Cleanup Helpers
    
    private func cleanupImageCache() {
        let originalCount = imageCache.countLimit
        imageCache.countLimit = max(5, originalCount / 2)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.imageCache.countLimit = originalCount
        }
    }
    
    // MARK: - Debug and Monitoring
    
    #if DEBUG
    func getDetailedMemoryInfo() -> String {
        let memoryStatus = getCurrentMemoryStatus()
        let warningCount = memoryWarningCount
        let imageCacheInfo = "Images: \(imageCache.countLimit) max, \(fontCache.count) fonts cached"
        let usedMemory = getCurrentMemoryUsage()
        let pressureLevel = usedMemory > memoryThreshold ? "High" : "Normal"
        
        return """
        Status: \(memoryStatus)
        Pressure Level: \(pressureLevel)
        Warning Count: \(warningCount)
        Cache Info: \(imageCacheInfo)
        Threshold: \(ByteCountFormatter().string(fromByteCount: Int64(memoryThreshold)))
        """
    }
    #endif
    
    // MARK: - Debug Helpers
    
    func debugInfo() -> String {
        let status = getCurrentMemoryStatus()
        return """
        Memory Manager Status:
        \(status)
        Warning Count: \(memoryWarningCount)
        """
    }
    
    // MARK: - Cleanup
    
    deinit {
        monitoringTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Supporting Types

private enum MemoryPressureLevel: String {
    case normal = "Normal"
    case high = "High"
} 