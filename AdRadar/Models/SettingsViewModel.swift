import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var imageURL: URL? = nil
    @Published var isSignedOut: Bool = false
    
    // Account Information
    @Published var publisherId: String = ""
    @Published var publisherName: String = ""
    @Published var timeZone: String = ""
    @Published var currency: String = ""
    
    // Payment Threshold
    @Published var paymentThreshold: Double = 100.0
    @Published var demoPaymentThreshold: Double = 100.0 // Demo mode threshold
    
    // AdMob Apps Visibility
    @Published var showAdMobApps: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    var authViewModel: AuthViewModel
    
    // Computed properties to get the appropriate values based on demo mode
    var currentPaymentThreshold: Double {
        authViewModel.isDemoMode ? demoPaymentThreshold : paymentThreshold
    }
    
    var currentPublisherId: String {
        authViewModel.isDemoMode ? "pub-1234567890345678" : publisherId
    }
    
    var currentPublisherName: String {
        authViewModel.isDemoMode ? "Demo User" : publisherName
    }
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        
        authViewModel.$userName.assign(to: &$name)
        authViewModel.$userEmail.assign(to: &$email)
        authViewModel.$userProfileImageURL.assign(to: &$imageURL)
        
        // Always initialize demo threshold independently - never based on user settings
        self.demoPaymentThreshold = UserDefaults.standard.object(forKey: "demoPaymentThreshold") as? Double ?? 100.0
        
        // Initialize account information from UserDefaults or use demo values
        if authViewModel.isDemoMode {
            self.publisherId = "pub-1234567890345678"
            self.publisherName = "Demo User"
            self.timeZone = "America/New_York"
            self.currency = "USD"
            self.paymentThreshold = 100.0
            // Demo threshold is already initialized above
        } else {
            // Initialize account information from UserDefaults
            self.publisherId = UserDefaults.standard.string(forKey: "publisherId") ?? ""
            self.publisherName = UserDefaults.standard.string(forKey: "publisherName") ?? ""
            self.timeZone = UserDefaults.standard.string(forKey: "timeZone") ?? Foundation.TimeZone.current.identifier
            
            // Get currency from UserDefaults or use the user's locale currency
            if let savedCurrency = UserDefaults.standard.string(forKey: "currency") {
                self.currency = savedCurrency
            } else {
                // Get the currency code from the user's locale
                let locale = Locale.current
                if let currencyCode = locale.currency?.identifier {
                    self.currency = currencyCode
                    // Save it to UserDefaults for future use
                    UserDefaults.standard.set(currencyCode, forKey: "currency")
                } else {
                    // Fallback to USD if currency code can't be determined
                    self.currency = "USD"
                }
            }
            
            // Initialize payment threshold - default based on currency
            if let savedThreshold = UserDefaults.standard.object(forKey: "paymentThreshold") as? Double {
                self.paymentThreshold = savedThreshold
            } else {
                // Set default thresholds based on currency
                switch currency {
                case "USD", "EUR", "GBP", "CAD", "AUD":
                    self.paymentThreshold = 100.0
                case "ZAR":
                    self.paymentThreshold = 1000.0
                case "INR":
                    self.paymentThreshold = 8000.0
                case "JPY":
                    self.paymentThreshold = 12000.0
                case "BRL":
                    self.paymentThreshold = 500.0
                case "MXN":
                    self.paymentThreshold = 2000.0
                default:
                    self.paymentThreshold = 100.0
                }
                // Save default threshold
                UserDefaults.standard.set(self.paymentThreshold, forKey: "paymentThreshold")
            }
            
            // Demo threshold remains independent - already initialized above
        }
        
        // Initialize AdMob Apps visibility (default: false)
        self.showAdMobApps = UserDefaults.standard.bool(forKey: "showAdMobApps")
        
        // Fetch account information when initialized (only if not in demo mode)
        if !authViewModel.isDemoMode {
            Task {
                await fetchAccountInfo()
            }
        }
    }
    
    func signOut(authViewModel: AuthViewModel) {
        authViewModel.signOut()
        self.isSignedOut = true
    }
    
    func deleteAccount(authViewModel: AuthViewModel) {
        // Clear all SettingsViewModel data
        self.publisherId = ""
        self.publisherName = ""
        self.timeZone = ""
        self.currency = ""
        self.paymentThreshold = 100.0
        self.demoPaymentThreshold = 100.0
        self.showAdMobApps = false
        
        // Clear all relevant UserDefaults keys used by SettingsViewModel
        let settingsKeys = [
            "publisherId",
            "publisherName",
            "timeZone", 
            "currency",
            "paymentThreshold",
            "demoPaymentThreshold",
            "showAdMobApps"
        ]
        
        for key in settingsKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        UserDefaults.standard.synchronize()
        
        // Perform comprehensive account deletion through AuthViewModel
        authViewModel.deleteAccount()
        
        self.isSignedOut = true
    }
    
    func updatePaymentThreshold(_ threshold: Double) {
        if authViewModel.isDemoMode {
            self.demoPaymentThreshold = threshold
            // Save demo threshold separately to avoid cross-contamination
            UserDefaults.standard.set(threshold, forKey: "demoPaymentThreshold")
        } else {
            self.paymentThreshold = threshold
            UserDefaults.standard.set(threshold, forKey: "paymentThreshold")
        }
    }
    
    func updateAdMobAppsVisibility(_ isVisible: Bool) {
        self.showAdMobApps = isVisible
        UserDefaults.standard.set(isVisible, forKey: "showAdMobApps")
    }
    
    @MainActor
    func fetchAccountInfo() async {
        // Don't fetch account info in demo mode
        guard !authViewModel.isDemoMode, let accessToken = authViewModel.accessToken else { return }
        
        switch await AdSenseAPI.shared.fetchAccountInfo(accessToken: accessToken) {
        case .success(let account):
            // Extract publisher ID from account name (format: accounts/pub-XXXXXXXX)
            if let publisherId = account.name.split(separator: "/").last {
                self.publisherId = String(publisherId)
                UserDefaults.standard.set(self.publisherId, forKey: "publisherId")
            }
            
            self.publisherName = account.displayName
            UserDefaults.standard.set(self.publisherName, forKey: "publisherName")
            
            if let timeZone = account.timeZone?.id {
                self.timeZone = timeZone
                UserDefaults.standard.set(self.timeZone, forKey: "timeZone")
            }
            
        case .failure(let error):
            print("Failed to fetch account info: \(error)")
        }
    }
}

extension UserDefaults {
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
} 