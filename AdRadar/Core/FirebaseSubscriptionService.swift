import Foundation
import FirebaseDatabase
import FirebaseAuth
import Combine

@MainActor
class FirebaseSubscriptionService: ObservableObject {
    static let shared = FirebaseSubscriptionService()
    
    private let database = Database.database().reference()
    private let subscriptionsCollection = "subscriptions"
    
    @Published var isUploading = false
    @Published var uploadError: String?
    
    private init() {}
    
    // MARK: - Subscription Data Model
    
    struct SubscriptionData: Codable {
        let email: String
        let isPro: Bool
        let lastUpdated: Date
        let plan: String
        let uid: String
        
        init(email: String, isPro: Bool, plan: String, uid: String) {
            self.email = email
            self.isPro = isPro
            self.lastUpdated = Date()
            self.plan = plan
            self.uid = uid
        }
    }
    
    // MARK: - Upload Subscription Data
    
    func uploadSubscriptionData(
        email: String,
        isPro: Bool,
        plan: String,
        uid: String
    ) async {
        guard !email.isEmpty && !uid.isEmpty else {
            print("❌ [FirebaseSubscription] Invalid data for upload: email=\(email), uid=\(uid)")
            return
        }
        
        await MainActor.run {
            isUploading = true
            uploadError = nil
        }
        
        do {
            let subscriptionData = SubscriptionData(
                email: email,
                isPro: isPro,
                plan: plan,
                uid: uid
            )
            
            // Convert to dictionary for Firebase
            let dataDict = try subscriptionData.asDictionary()
            
            // Upload to Firebase
            let subscriptionRef = database.child(subscriptionsCollection).child(uid)
            
            try await subscriptionRef.setValue(dataDict)
            
            print("✅ [FirebaseSubscription] Successfully uploaded subscription data for user: \(uid)")
            print("📊 [FirebaseSubscription] Data: email=\(email), isPro=\(isPro), plan=\(plan)")
            
            await MainActor.run {
                isUploading = false
            }
            
        } catch {
            print("❌ [FirebaseSubscription] Failed to upload subscription data: \(error.localizedDescription)")
            
            await MainActor.run {
                isUploading = false
                uploadError = error.localizedDescription
            }
        }
    }
    
    // MARK: - Update Subscription Status
    
    func updateSubscriptionStatus(
        email: String,
        isPro: Bool,
        plan: String,
        uid: String
    ) async {
        await uploadSubscriptionData(email: email, isPro: isPro, plan: plan, uid: uid)
    }
    
    // MARK: - Get Subscription Data
    
    func getSubscriptionData(for uid: String) async -> SubscriptionData? {
        do {
            let snapshot = try await database.child(subscriptionsCollection).child(uid).getData()
            
            guard let value = snapshot.value as? [String: Any] else {
                print("⚠️ [FirebaseSubscription] No subscription data found for user: \(uid)")
                return nil
            }
            
            // Parse the data
            let email = value["email"] as? String ?? ""
            let isPro = value["isPro"] as? Bool ?? false
            let plan = value["plan"] as? String ?? ""
            
            let subscriptionData = SubscriptionData(
                email: email,
                isPro: isPro,
                plan: plan,
                uid: uid
            )
            
            print("✅ [FirebaseSubscription] Retrieved subscription data for user: \(uid)")
            return subscriptionData
            
        } catch {
            print("❌ [FirebaseSubscription] Failed to get subscription data: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Delete Subscription Data
    
    func deleteSubscriptionData(for uid: String) async {
        do {
            try await database.child(subscriptionsCollection).child(uid).removeValue()
            print("✅ [FirebaseSubscription] Deleted subscription data for user: \(uid)")
        } catch {
            print("❌ [FirebaseSubscription] Failed to delete subscription data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    func clearUploadError() {
        uploadError = nil
    }
}

// MARK: - Codable Extension

extension FirebaseSubscriptionService.SubscriptionData {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "FirebaseSubscriptionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert to dictionary"])
        }
        return dictionary
    }
} 