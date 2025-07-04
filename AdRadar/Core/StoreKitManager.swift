import Foundation
import StoreKit
import Combine
import FirebaseDatabase
import CommonCrypto

@MainActor
public class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var subscriptionStatus: RenewalState?
    @Published var isLoading = false
    @Published var error: StoreKitError?
    
    private var updateListenerTask: Task<Void, Error>?
    private let productIdentifiers: Set<String> = [
        "com.delteqis.adradar.pro_monthly_sub",
        "com.delteqis.adradar.pro_yearly_sub"
    ]
    
    public enum StoreKitError: Error, LocalizedError {
        case failedVerification
        case unknownError
        case systemError(Error)
        case userCancelled
        case paymentNotAllowed
        case productNotAvailable
        
        public var errorDescription: String? {
            switch self {
            case .failedVerification:
                return "Purchase verification failed"
            case .unknownError:
                return "An unknown error occurred"
            case .systemError(let error):
                return error.localizedDescription
            case .userCancelled:
                return "Purchase was cancelled"
            case .paymentNotAllowed:
                return "Payments are not allowed on this device"
            case .productNotAvailable:
                return "Product is not available"
            }
        }
    }
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        Task {
            // Load products and restore purchases
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        isLoading = true
        error = nil
        
        print("🔄 [StoreKit] Loading products for identifiers: \(productIdentifiers)")
        
        do {
            let storeProducts = try await Product.products(for: productIdentifiers)
            products = storeProducts.sorted { $0.price < $1.price }
            
            print("✅ [StoreKit] Successfully loaded \(products.count) products:")
            for product in products {
                print("📱 [StoreKit] - \(product.id): \(product.displayName) (\(product.displayPrice))")
            }
        } catch {
            self.error = .systemError(error)
            print("❌ [StoreKit] Failed to load products: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase Handling
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            
            // Deliver content to the user
            await updatePurchasedProducts()
            
            // Upload subscription data to Firebase
            await uploadSubscriptionToFirebase(product: product, transaction: transaction)
            
            // Always finish a transaction
            await transaction.finish()
            
        case .userCancelled:
            throw StoreKitError.userCancelled
            
        case .pending:
            // Transaction waiting on SCA (Strong Customer Authentication) or approval from a parent
            break
            
        @unknown default:
            throw StoreKitError.unknownError
        }
    }
    
    // MARK: - Transaction Verification
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Transaction Updates
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Iterate through any transactions that don't come from a direct call to `purchase()`
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    // Deliver products to the user
                    await self.updatePurchasedProducts()
                    
                    // Upload subscription data to Firebase for background transactions
                    await self.uploadSubscriptionToFirebase(transaction: transaction)
                    
                    // Always finish a transaction
                    await transaction.finish()
                } catch {
                    print("❌ [StoreKit] Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    // MARK: - Purchased Products
    
    @MainActor
    func updatePurchasedProducts() async {
        var purchasedProducts: Set<String> = []
        
        print("🔄 [StoreKit] Starting updatePurchasedProducts...")
        
        // Iterate through all unfinished transactions
        var transactionCount = 0
        for await result in Transaction.currentEntitlements {
            transactionCount += 1
            print("📱 [StoreKit] Processing transaction \(transactionCount): \(result)")
            
            do {
                let transaction = try checkVerified(result)
                
                print("📱 [StoreKit] Found transaction: \(transaction.productID), revoked: \(transaction.revocationDate != nil)")
                print("📱 [StoreKit] Transaction details: type=\(transaction.productType), expiration=\(transaction.expirationDate?.description ?? "none")")
                
                switch transaction.productType {
                case .nonConsumable:
                    purchasedProducts.insert(transaction.productID)
                    print("📱 [StoreKit] Added non-consumable: \(transaction.productID)")
                default:
                    // For subscriptions and other types, check if not revoked
                    if transaction.revocationDate == nil {
                        purchasedProducts.insert(transaction.productID)
                        print("📱 [StoreKit] Added subscription: \(transaction.productID)")
                    } else {
                        print("📱 [StoreKit] Skipped revoked subscription: \(transaction.productID)")
                    }
                }
            } catch {
                print("❌ [StoreKit] Failed to verify transaction: \(error)")
                print("❌ [StoreKit] Transaction verification error details: \(error.localizedDescription)")
            }
        }
        
        print("📱 [StoreKit] Processed \(transactionCount) transactions")
        print("📱 [StoreKit] Final purchased products: \(purchasedProducts)")
        self.purchasedProductIDs = purchasedProducts
    }
    
    // MARK: - Subscription Status
    
    func updateSubscriptionStatus() async {
        guard let product = products.first(where: { $0.subscription != nil }),
              let subscription = product.subscription else {
            return
        }
        
        let statuses = try? await subscription.status
        
        var highestStatus: Product.SubscriptionInfo.Status?
        var highestRenewalState: RenewalState?
        
        for status in statuses ?? [] {
            switch status.state {
            case .subscribed, .inGracePeriod, .inBillingRetryPeriod:
                let renewalInfo = try? checkVerified(status.renewalInfo)
                let transaction = try? checkVerified(status.transaction)
                
                if let renewalInfo = renewalInfo, let transaction = transaction {
                    if highestStatus == nil {
                        highestStatus = status
                        highestRenewalState = RenewalState(
                            transaction: transaction,
                            renewalInfo: renewalInfo
                        )
                    }
                }
            case .revoked, .expired:
                continue
            default:
                break
            }
        }
        
        subscriptionStatus = highestRenewalState
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        error = nil
        
        print("🔄 [StoreKit] Starting restore purchases...")
        
        // Sync with App Store to get latest transaction status
        print("🔄 [StoreKit] Syncing with App Store...")
        try? await AppStore.sync()
        print("✅ [StoreKit] App Store sync completed")
        
        // Update purchased products from current entitlements
        print("🔄 [StoreKit] Updating purchased products...")
        await updatePurchasedProducts()
        
        // Update subscription status
        print("🔄 [StoreKit] Updating subscription status...")
        await updateSubscriptionStatus()
        
        print("✅ [StoreKit] Restore purchases completed successfully")
        print("📱 [StoreKit] Current purchased products: \(purchasedProductIDs)")
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    func isPurchased(_ productID: String) -> Bool {
        return purchasedProductIDs.contains(productID)
    }
    
    func hasActivePremiumSubscription() -> Bool {
        return isPurchased("com.delteqis.adradar.pro_monthly_sub") ||
               isPurchased("com.delteqis.adradar.pro_yearly_sub")
    }
    
    func hasRemovedAds() -> Bool {
        return isPurchased("com.delteqis.adradar.pro_monthly_sub") ||
               isPurchased("com.delteqis.adradar.pro_yearly_sub") ||
               hasActivePremiumSubscription()
    }
    
    // MARK: - Firebase Integration
    
    private func uploadSubscriptionToFirebase(product: Product, transaction: Transaction) async {
        await uploadSubscriptionToFirebase(transaction: transaction)
    }
    
    private func uploadSubscriptionToFirebase(transaction: Transaction) async {
        // Get user information from AuthViewModel
        let authViewModel = AuthViewModel.shared
        
        // Skip if in demo mode
        if authViewModel.isDemoMode {
            print("📱 [StoreKit] Skipping Firebase upload in demo mode")
            return
        }
        
        // Get user email and generate UID
        let email = authViewModel.userEmail.isEmpty ? "unknown@example.com" : authViewModel.userEmail
        let uid = generateUserUID(email: email)
        
        // Determine subscription plan and status
        let plan = transaction.productID
        let isPro = isProSubscription(transaction.productID)
        
        print("📤 [StoreKit] Uploading subscription to Firebase: email=\(email), plan=\(plan), isPro=\(isPro)")
        
        // Upload to Firebase
        await FirebaseSubscriptionService.shared.uploadSubscriptionData(
            email: email,
            isPro: isPro,
            plan: plan,
            uid: uid
        )
    }
    
    private func generateUserUID(email: String) -> String {
        // Create a consistent UID based on email
        let sanitizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let data = Data(sanitizedEmail.utf8)
        let hash = data.sha256()
        return hash.hexString
    }
    
    private func isProSubscription(_ productID: String) -> Bool {
        return productID.contains("pro_monthly_sub") || 
               productID.contains("pro_yearly_sub") ||
               productID.contains("premium")
    }
}

// MARK: - Supporting Types

public struct RenewalState {
    let transaction: Transaction
    let renewalInfo: Product.SubscriptionInfo.RenewalInfo
    
    var isActive: Bool {
        // Check if transaction is not revoked and hasn't expired
        guard transaction.revocationDate == nil else { return false }
        guard let expirationDate = transaction.expirationDate else { return true }
        return expirationDate > Date()
    }
    
    var willRenew: Bool {
        renewalInfo.willAutoRenew && transaction.revocationDate == nil
    }
    
    var expirationDate: Date? {
        transaction.expirationDate
    }
} 
