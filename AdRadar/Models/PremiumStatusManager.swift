import Foundation
import Combine
import StoreKit
import CommonCrypto

@MainActor
class PremiumStatusManager: ObservableObject {
    static let shared = PremiumStatusManager()
    
    @Published var isPremiumUser: Bool = false
    @Published var hasRemovedAds: Bool = false
    @Published var premiumFeatures: Set<PremiumFeature> = []
    @Published var subscriptionStatus: SubscriptionStatus?
    @Published var isLoading: Bool = false
    
    private let storeKitManager = StoreKitManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum PremiumFeature: String, CaseIterable {
        case advancedAnalytics
        case unlimitedHistory
        case prioritySupport
        case adFree
        case exportData
        case customAlerts
        
        var displayName: String {
            switch self {
            case .advancedAnalytics:
                return "Advanced Analytics"
            case .unlimitedHistory:
                return "Unlimited History"
            case .prioritySupport:
                return "Priority Support"
            case .adFree:
                return "Ad-Free Experience"
            case .exportData:
                return "Export Data"
            case .customAlerts:
                return "Custom Alerts"
            }
        }
        
        var description: String {
            switch self {
            case .advancedAnalytics:
                return "Detailed insights and performance trends"
            case .unlimitedHistory:
                return "Access all historical data without limits"
            case .prioritySupport:
                return "Fast customer support and direct assistance"
            case .adFree:
                return "Remove all advertisements from the app"
            case .exportData:
                return "Export your data in multiple formats"
            case .customAlerts:
                return "Set custom notifications and alerts"
            }
        }
        
        var iconName: String {
            switch self {
            case .advancedAnalytics:
                return "chart.line.uptrend.xyaxis"
            case .unlimitedHistory:
                return "calendar"
            case .prioritySupport:
                return "bell.badge"
            case .adFree:
                return "eye.slash"
            case .exportData:
                return "square.and.arrow.up"
            case .customAlerts:
                return "bell.and.waves.left.and.right"
            }
        }
    }
    
    enum SubscriptionStatus {
        case active
        case expired
        case inGracePeriod
        case inBillingRetryPeriod
        case revoked
        case none
        
        var displayName: String {
            switch self {
            case .active:
                return "Active"
            case .expired:
                return "Expired"
            case .inGracePeriod:
                return "Grace Period"
            case .inBillingRetryPeriod:
                return "Billing Retry"
            case .revoked:
                return "Revoked"
            case .none:
                return "None"
            }
        }
        
        var isValid: Bool {
            switch self {
            case .active, .inGracePeriod, .inBillingRetryPeriod:
                return true
            case .expired, .revoked, .none:
                return false
            }
        }
    }
    
    private init() {
        setupObservers()
        updatePremiumStatus()
    }
    
    private func setupObservers() {
        // Listen to StoreKit manager changes
        storeKitManager.$purchasedProductIDs
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updatePremiumStatus()
                }
            }
            .store(in: &cancellables)
        
        storeKitManager.$subscriptionStatus
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updatePremiumStatus()
                }
            }
            .store(in: &cancellables)
    }
    
    func updatePremiumStatus() {
        // Check if user has active premium subscription
        isPremiumUser = storeKitManager.hasActivePremiumSubscription()
        
        // Check if user has removed ads
        hasRemovedAds = storeKitManager.hasRemovedAds()
        
        // Update premium features based on purchases
        updatePremiumFeatures()
        
        // Update subscription status
        updateSubscriptionStatus()
        
        // Note: Firebase database upload removed - subscription data no longer uploaded
    }
    
    private func updatePremiumFeatures() {
        var features: Set<PremiumFeature> = []
        
        if isPremiumUser {
            // Premium subscription includes all features
            features = Set(PremiumFeature.allCases)
        } else {
            // Check individual purchases
            if storeKitManager.isPurchased("com.delteqis.adradar.pro_monthly_sub") {
                features.insert(.adFree)
            }
        }
        
        premiumFeatures = features
    }
    
    private func updateSubscriptionStatus() {
        guard let renewalState = storeKitManager.subscriptionStatus else {
            subscriptionStatus = SubscriptionStatus.none
            return
        }
        
        // Check if subscription is revoked
        if renewalState.transaction.revocationDate != nil {
            subscriptionStatus = .revoked
        } else if renewalState.isActive {
            subscriptionStatus = .active
        } else {
            subscriptionStatus = .expired
        }
    }
    
    // MARK: - Feature Access Methods
    
    func hasFeature(_ feature: PremiumFeature) -> Bool {
        // Only bypass premium gates in demo mode
        if AuthViewModel.shared.isDemoMode {
            return true
        }
        // For real users, check if they have purchased the feature
        return premiumFeatures.contains(feature)
    }
    
    func canAccessAdvancedAnalytics() -> Bool {
        return hasFeature(.advancedAnalytics)
    }
    
    func canAccessUnlimitedHistory() -> Bool {
        return hasFeature(.unlimitedHistory)
    }
    
    func canAccessPrioritySupport() -> Bool {
        return hasFeature(.prioritySupport)
    }
    
    func shouldShowAds() -> Bool {
        return !hasFeature(.adFree)
    }
    
    func canExportData() -> Bool {
        return hasFeature(.exportData)
    }
    
    func canSetCustomAlerts() -> Bool {
        return hasFeature(.customAlerts)
    }
    
    // MARK: - Purchase Methods
    
    func purchasePremiumMonthly() async throws {
        guard let product = storeKitManager.products.first(where: { $0.id == "com.delteqis.adradar.pro_monthly_sub" }) else {
            throw StoreKitManager.StoreKitError.productNotAvailable
        }
        try await storeKitManager.purchase(product)
    }
    
    func purchasePremiumYearly() async throws {
        guard let product = storeKitManager.products.first(where: { $0.id == "com.delteqis.adradar.pro_yearly_sub" }) else {
            throw StoreKitManager.StoreKitError.productNotAvailable
        }
        try await storeKitManager.purchase(product)
    }
    
    func purchaseRemoveAds() async throws {
        guard let product = storeKitManager.products.first(where: { $0.id == "com.delteqis.adradar.pro_monthly_sub" }) else {
            throw StoreKitManager.StoreKitError.productNotAvailable
        }
        try await storeKitManager.purchase(product)
    }
    
    func restorePurchases() async {
        isLoading = true
        await storeKitManager.restorePurchases()
        isLoading = false
    }
    
    // MARK: - Subscription Management
    
    var subscriptionExpirationDate: Date? {
        return storeKitManager.subscriptionStatus?.expirationDate
    }
    
    var willAutoRenew: Bool {
        return storeKitManager.subscriptionStatus?.willRenew ?? false
    }
    
    func openSubscriptionManagement() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            Task {
                try? await AppStore.showManageSubscriptions(in: windowScene)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func formattedSubscriptionStatus() -> String {
        guard let status = subscriptionStatus else { return "No subscription" }
        
        var statusText = status.displayName
        
        if let expirationDate = subscriptionExpirationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            statusText += " (expires: \(formatter.string(from: expirationDate)))"
        }
        
        return statusText
    }
    
    func shouldShowUpgradePrompt(for feature: PremiumFeature) -> Bool {
        return !hasFeature(feature) && !isPremiumUser
    }
    
    // MARK: - Usage Analytics
    
    func trackFeatureUsage(_ feature: PremiumFeature) {
        // Track feature usage for analytics
        #if DEBUG
        print("📊 Feature used: \(feature.displayName) - Access: \(hasFeature(feature) ? "Granted" : "Denied")")
        #endif
        
        // You can integrate with your analytics service here
        // Analytics.track("feature_usage", parameters: [
        //     "feature": feature.rawValue,
        //     "access_granted": hasFeature(feature),
        //     "is_premium": isPremiumUser
        // ])
    }
    
    // MARK: - Firebase Integration (Removed)
    
    // Note: Firebase database integration has been removed
    // Subscription data is no longer uploaded to Firebase
    
    private func getCurrentPlan() -> String {
        // Determine the current subscription plan
        if storeKitManager.isPurchased("com.delteqis.adradar.pro_yearly_sub") {
            return "com.delteqis.adradar.pro_yearly_sub"
        } else if storeKitManager.isPurchased("com.delteqis.adradar.pro_monthly_sub") {
            return "com.delteqis.adradar.pro_monthly_sub"
        } else {
            return "none"
        }
    }

    var currentPlanDisplayName: String {
        let planID = getCurrentPlan()
        switch planID {
        case "com.delteqis.adradar.pro_monthly_sub":
            return "Monthly"
        case "com.delteqis.adradar.pro_yearly_sub":
            return "Yearly"
        default:
            return "None"
        }
    }
}

// MARK: - Data Extension for SHA256

extension Data {
    func sha256() -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(count), &hash)
        }
        return Data(hash)
    }
    
    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
} 