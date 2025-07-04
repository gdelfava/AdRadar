// App entry point for AdRadar
//
//  AdRadar_App.swift
//  AdRadar
//
//  Created by Guilio Del Fava on 2025/06/12.
//

import SwiftUI
import Combine
import GoogleSignIn
import FirebaseCore

@main
struct AdRadar_App: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var backgroundDataManager = BackgroundDataManager.shared
    @StateObject private var storeKitManager = StoreKitManager.shared
    @StateObject private var premiumStatusManager = PremiumStatusManager.shared
    @StateObject private var firebaseSubscriptionService = FirebaseSubscriptionService.shared
    
    init() {
        // Initialize Firebase first
        FirebaseApp.configure()
        
        setupAppEnvironment()
        // Initialize memory monitoring
        setupMemoryMonitoring()
        // Initialize background data management
        setupBackgroundDataManager()
        // Initialize StoreKit
        setupStoreKit()
        // Configure Google Sign In
        configureGoogleSignIn()
    }
    
    private func setupAppEnvironment() {
        // Configure Sora fonts globally
        configureFonts()
        
        // Initialize core managers in a controlled manner
        initializeManagers()
        
        // Log initialization status
        logInitializationStatus()
    }
    
    private func configureFonts() {
        // Configure navigation and tab bar fonts with Sora
        SoraNavigationAppearance.configure()
        
        // Load and verify Sora fonts
        SoraFontLoader.loadFonts()
    }
    
    private func initializeManagers() {
        // Initialize UserDefaultsManager first (safer)
        _ = UserDefaultsManager.shared
        
        // Initialize MemoryManager with delayed setup
        DispatchQueue.main.async {
            _ = MemoryManager.shared
        }
        
        // Initialize WatchDataSyncService for Apple Watch connectivity
        Task { @MainActor in
            _ = WatchDataSyncService.shared
        }
    }
    
    private func setupBackgroundDataManager() {
        // Initialize background data manager on main thread
        Task { @MainActor in
            BackgroundDataManager.shared.initialize()
        }
    }
    
    private func setupStoreKit() {
        // Initialize StoreKit managers on main thread
        Task { @MainActor in
            _ = StoreKitManager.shared
            _ = PremiumStatusManager.shared
        }
    }
    
    private func configureGoogleSignIn() {
        print("🔧 [App] Configuring Google Sign-In...")
        
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            // Fall back to Info.plist if GoogleService-Info.plist doesn't exist
            guard let clientId = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
                print("❌ [App] No Google Sign-In client ID found in GoogleService-Info.plist or Info.plist")
                print("📋 [App] Please ensure you have:")
                print("   1. GoogleService-Info.plist with CLIENT_ID")
                print("   2. OR GIDClientID in Info.plist")
                return
            }
            print("📱 [App] Using client ID from Info.plist: \(clientId)")
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
            print("✅ [App] Google Sign-In configured successfully from Info.plist")
            return
        }
        
        print("📁 [App] Using client ID from GoogleService-Info.plist: \(clientId)")
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        print("✅ [App] Google Sign-In configured successfully from GoogleService-Info.plist")
        
        // Verify configuration
        if GIDSignIn.sharedInstance.configuration != nil {
            print("✅ [App] Google Sign-In configuration verified")
        } else {
            print("❌ [App] Google Sign-In configuration failed")
        }
    }
    
    private func logInitializationStatus() {
        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let userDefaultsStatus = UserDefaultsManager.shared.getContainerStatus()
            let memoryInfo = MemoryManager.shared.getCurrentMemoryStatus()
            
            print("""
            [AdRadar] App initialization completed:
            - \(userDefaultsStatus)
            - Initial memory usage: \(memoryInfo)
            - Build configuration: DEBUG
            """)
        }
        #else
        print("[AdRadar] App initialized successfully (Release)")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreenWrapper()
                .environmentObject(authViewModel)
                .environmentObject(NetworkMonitor.shared)
                .environmentObject(backgroundDataManager)
                .environmentObject(storeKitManager)
                .environmentObject(premiumStatusManager)
                .environmentObject(firebaseSubscriptionService)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Check memory when app becomes active
                    let memoryPressureDetected = MemoryManager.shared.checkMemoryPressure()
                    if memoryPressureDetected {
                        print("[App] Memory pressure detected on app activation - cleanup performed")
                    }
                    
                    // Handle app becoming active for background data manager
                    Task { @MainActor in
                        BackgroundDataManager.shared.handleAppBecomeActive()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    // Clean up when app goes to background
                    MemoryManager.shared.performMaintenanceCleanup()
                    
                    // Handle app entering background for background data manager
                    Task { @MainActor in
                        BackgroundDataManager.shared.handleAppEnterBackground()
                    }
                }
                .onOpenURL { url in
                    // Handle Google Sign In URL
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
    
    private func setupMemoryMonitoring() {
        #if DEBUG
        // Start periodic memory monitoring in debug builds
        startPeriodicMemoryLogging()
        #endif
    }
    
    #if DEBUG
    private func startPeriodicMemoryLogging() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            let usage = MemoryManager.shared.getCurrentMemoryUsage()
            let usageMB = Double(usage) / (1024 * 1024)
            
            if usageMB > 250 {
                print("⚠️ [MemoryMonitor] High memory usage: \(String(format: "%.1f", usageMB)) MB")
                let cleanupPerformed = MemoryManager.shared.checkMemoryPressure()
                if cleanupPerformed {
                    print("🧹 [MemoryMonitor] Automatic cleanup performed")
                }
            } else {
                print("📊 [MemoryMonitor] Memory usage: \(String(format: "%.1f", usageMB)) MB")
            }
        }
    }
    #endif
    
    func checkMemoryAndPerformCleanup() {
        // Check current memory usage and perform cleanup if needed
        let currentUsage = MemoryManager.shared.getCurrentMemoryUsage()
        let memoryStatus = MemoryManager.shared.getCurrentMemoryStatus()
        print("[App] Current memory status: \(memoryStatus)")
        
        if currentUsage > 150 * 1024 * 1024 { // 150MB threshold
            print("[App] High memory usage detected - performing cleanup")
            MemoryManager.shared.performMaintenanceCleanup()
        }
    }
    
    func performBackgroundCleanup() {
        print("[App] Performing background cleanup")
        MemoryManager.shared.performMaintenanceCleanup()
        
        // Check if cleanup was effective
        let memoryStatus = MemoryManager.shared.getCurrentMemoryStatus()
        print("[App] Memory status after cleanup: \(memoryStatus)")
    }
}

// MARK: - Splash Screen Wrapper
struct SplashScreenWrapper: View {
    @State private var showSplash = true
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(networkMonitor)
                    .transition(.opacity)
                    .zIndex(0)
            }
        }
        .onReceive(Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()) { _ in
            withAnimation(.easeInOut(duration: 0.8)) {
                showSplash = false
            }
        }
    }
} 