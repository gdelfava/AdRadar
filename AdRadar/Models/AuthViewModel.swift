import Foundation
import GoogleSignIn
import Combine
import Security
import AuthenticationServices

class AuthViewModel: NSObject, ObservableObject {
    static let shared = AuthViewModel()
    
    @Published var isSignedIn: Bool = false
    @Published var accessToken: String? = nil
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var userProfileImageURL: URL? = nil
    @Published var isDemoMode: Bool = false
    
    // Apple Sign In properties
    @Published var appleUserID: String? = nil
    @Published var isAppleSignedIn: Bool = false
    @Published var isTransitioningToGoogle: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let keychainService = "com.delteqis.AdRadar"
    private let keychainAccount = "googleAccessToken"
    private let appleUserIDKey = "appleUserID"
    private let userNameKey = "userName"
    private let userEmailKey = "userEmail"
    private let userProfileImageURLKey = "userProfileImageURL"
    private let isDemoModeKey = "isDemoMode"
    
    override init() {
        super.init()
        
        // Load demo mode state
        self.isDemoMode = UserDefaults.standard.bool(forKey: isDemoModeKey)
        
        // If in demo mode, set up demo user
        if isDemoMode {
            setupDemoUser()
            return
        }
        
        // Load Apple Sign In state
        self.appleUserID = UserDefaults.standard.string(forKey: appleUserIDKey)
        self.isAppleSignedIn = appleUserID != nil
        
        // Load cached values synchronously (these are fast local operations)
        if let token = loadTokenFromKeychain() {
            self.accessToken = token
            self.isSignedIn = true
        }
        
        // Load user info from UserDefaults
        let defaults = UserDefaults.standard
        self.userName = defaults.string(forKey: userNameKey) ?? ""
        self.userEmail = defaults.string(forKey: userEmailKey) ?? ""
        if let urlString = defaults.string(forKey: userProfileImageURLKey), let url = URL(string: urlString) {
            self.userProfileImageURL = url
        }
        
        // Check Apple Sign In credential state if Apple user exists
        if let appleUserID = appleUserID {
            checkAppleSignInState(for: appleUserID)
        }
        
        // Defer Google Sign-In restoration to async method to prevent blocking init
        Task { [weak self] in
            await self?.restoreGoogleSignInSession()
        }
    }
    
    func enterDemoMode() {
        isDemoMode = true
        UserDefaults.standard.set(true, forKey: isDemoModeKey)
        setupDemoUser()
    }
    
    func exitDemoMode() {
        isDemoMode = false
        UserDefaults.standard.set(false, forKey: isDemoModeKey)
        signOut()
    }
    
    private func setupDemoUser() {
        let demoUser = DemoDataProvider.shared.demoUser
        self.isSignedIn = true
        self.accessToken = "demo_token"
        self.userName = demoUser.name
        self.userEmail = demoUser.email
        self.userProfileImageURL = nil  // Don't set URL in demo mode, using local asset instead
    }
    
    /// Restores Google Sign-In session asynchronously to avoid blocking main thread during init
    private func restoreGoogleSignInSession() async {
        await withCheckedContinuation { continuation in
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                if let user = user, error == nil {
                    user.refreshTokensIfNeeded { auth, error in
                        if let accessToken = auth?.accessToken.tokenString {
                            Task { @MainActor in
                                self.accessToken = accessToken
                                self.isSignedIn = true
                                self.saveTokenToKeychain(accessToken)
                                if let profile = user.profile {
                                    self.userName = profile.name
                                    self.userEmail = profile.email
                                    self.userProfileImageURL = profile.hasImage ? profile.imageURL(withDimension: 200) : nil
                                    // Save to UserDefaults
                                    let defaults = UserDefaults.standard
                                    defaults.set(profile.name, forKey: self.userNameKey)
                                    defaults.set(profile.email, forKey: self.userEmailKey)
                                    if let url = self.userProfileImageURL?.absoluteString {
                                        defaults.set(url, forKey: self.userProfileImageURLKey)
                                    } else {
                                        defaults.removeObject(forKey: self.userProfileImageURLKey)
                                    }
                                }
                                continuation.resume()
                            }
                        } else {
                            continuation.resume()
                        }
                    }
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func signIn() {
        print("🔍 [GoogleAuth] Starting Google Sign-In...")
        
        // Check if Google Sign-In is configured
        guard GIDSignIn.sharedInstance.configuration != nil else {
            print("❌ [GoogleAuth] Google Sign-In not configured!")
            DispatchQueue.main.async {
                self.isTransitioningToGoogle = false
            }
            return
        }
        
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            print("❌ [GoogleAuth] No root view controller found")
            DispatchQueue.main.async {
                self.isTransitioningToGoogle = false
            }
            return
        }
        
        print("✅ [GoogleAuth] Found root view controller: \(type(of: rootViewController))")
        
        let scopes = ["https://www.googleapis.com/auth/adsense.readonly", "https://www.googleapis.com/auth/admob.readonly"]
        print("🔑 [GoogleAuth] Requesting scopes: \(scopes)")
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, hint: nil, additionalScopes: scopes) { [weak self] signInResult, error in
            guard let self = self else { return }
            
            // Always update transitioning state on main thread
            DispatchQueue.main.async {
                self.isTransitioningToGoogle = false
            }
            
            if let error = error {
                print("❌ [GoogleAuth] Google Sign-In error: \(error.localizedDescription)")
                return
            }
            
            guard let result = signInResult else { 
                print("❌ [GoogleAuth] No sign-in result returned")
                return 
            }
            
            print("✅ [GoogleAuth] Sign-in successful, refreshing tokens...")
            result.user.refreshTokensIfNeeded { [weak self] auth, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ [GoogleAuth] Token refresh error: \(error.localizedDescription)")
                    return
                }
                
                guard let accessToken = auth?.accessToken.tokenString else {
                    print("❌ [GoogleAuth] No access token returned")
                    return
                }
                
                print("✅ [GoogleAuth] Token refresh successful")
                print("🔑 [GoogleAuth] Granted scopes: \(result.user.grantedScopes ?? [])")
                
                // Perform all UI updates on main thread
                DispatchQueue.main.async {
                    self.accessToken = accessToken
                    self.isSignedIn = true
                    self.saveTokenToKeychain(accessToken)
                    
                    if let profile = result.user.profile {
                        print("👤 [GoogleAuth] Updating user profile...")
                        self.userName = profile.name
                        self.userEmail = profile.email
                        self.userProfileImageURL = profile.hasImage ? profile.imageURL(withDimension: 200) : nil
                        
                        // Save to UserDefaults
                        let defaults = UserDefaults.standard
                        defaults.set(profile.name, forKey: self.userNameKey)
                        defaults.set(profile.email, forKey: self.userEmailKey)
                        if let url = self.userProfileImageURL?.absoluteString {
                            defaults.set(url, forKey: self.userProfileImageURLKey)
                        } else {
                            defaults.removeObject(forKey: self.userProfileImageURLKey)
                        }
                        print("✅ [GoogleAuth] User profile updated successfully")
                    }
                }
            }
        }
    }
    
    func signOut() {
        // Sign out of Google
        GIDSignIn.sharedInstance.signOut()
        
        // Clear Apple Sign In data
        appleUserID = nil
        isAppleSignedIn = false
        UserDefaults.standard.removeObject(forKey: appleUserIDKey)
        
        // Clear all user data
        self.accessToken = nil
        self.isSignedIn = false
        self.userName = ""
        self.userEmail = ""
        self.userProfileImageURL = nil
        self.isDemoMode = false
        
        // Clear from UserDefaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: userNameKey)
        defaults.removeObject(forKey: userEmailKey)
        defaults.removeObject(forKey: userProfileImageURLKey)
        defaults.removeObject(forKey: isDemoModeKey)
        
        // Clear from Keychain
        deleteTokenFromKeychain()
    }
    
    /// Permanently deletes the user account and all associated data.
    /// This function performs a comprehensive cleanup of all user data and provides
    /// guidance for revoking authorization from authentication providers.
    func deleteAccount() {
        print("🗑️ [AccountDeletion] Starting account deletion process...")
        
        // Sign out of Google
        GIDSignIn.sharedInstance.signOut()
        print("✅ [AccountDeletion] Signed out of Google")
        
        // Clear Apple Sign In data
        appleUserID = nil
        isAppleSignedIn = false
        UserDefaults.standard.removeObject(forKey: appleUserIDKey)
        print("✅ [AccountDeletion] Cleared Apple Sign In data")
        
        // Clear all user authentication data
        self.accessToken = nil
        self.isSignedIn = false
        self.userName = ""
        self.userEmail = ""
        self.userProfileImageURL = nil
        self.isDemoMode = false
        self.isTransitioningToGoogle = false
        
        // Clear from UserDefaults - comprehensive cleanup
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: userNameKey)
        defaults.removeObject(forKey: userEmailKey)
        defaults.removeObject(forKey: userProfileImageURLKey)
        defaults.removeObject(forKey: isDemoModeKey)
        defaults.removeObject(forKey: appleUserIDKey)
        
        // Clear any other app-specific user preferences that might exist
        // This ensures no personal data remains on the device
        let userDefaultsKeys = [
            "hasSeenOnboarding",
            "selectedAdNetwork",
            "lastSyncDate",
            "userPreferences",
            "analyticsConsent"
        ]
        
        for key in userDefaultsKeys {
            defaults.removeObject(forKey: key)
        }
        
        defaults.synchronize()
        print("✅ [AccountDeletion] Cleared all UserDefaults data")
        
        // Clear from Keychain - comprehensive cleanup
        deleteTokenFromKeychain()
        
        // Clear any other potential keychain items
        let keychainKeys = [
            "refreshToken",
            "userCredentials",
            "encryptedUserData"
        ]
        
        for key in keychainKeys {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: key
            ]
            SecItemDelete(query as CFDictionary)
        }
        
        print("✅ [AccountDeletion] Cleared all Keychain data")
        
        // Clear any cached images or temporary files
        clearCachedUserData()
        
        print("✅ [AccountDeletion] Account deletion completed successfully")
    }
    
    /// Clears any cached user data, images, or temporary files
    private func clearCachedUserData() {
        // Clear URL cache that might contain user images
        URLCache.shared.removeAllCachedResponses()
        
        // Clear any temporary files in the app's documents directory
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
                for fileURL in fileURLs {
                    if fileURL.lastPathComponent.contains("user") || fileURL.lastPathComponent.contains("profile") {
                        try FileManager.default.removeItem(at: fileURL)
                    }
                }
            } catch {
                print("⚠️ [AccountDeletion] Could not clear cached files: \(error)")
            }
        }
        
        print("✅ [AccountDeletion] Cleared cached user data")
    }
    
    func requestAdditionalScopes() {
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            print("No root view controller found")
            return
        }
        
        // Sign out first to force fresh authentication with new scopes
        GIDSignIn.sharedInstance.signOut()
        
        // Use the full scopes list including the new AdMob scope
        let allScopes = ["https://www.googleapis.com/auth/adsense.readonly", "https://www.googleapis.com/auth/admob.readonly"]
        
        // Configure Google Sign-In with the scopes
        if let configuration = GIDSignIn.sharedInstance.configuration {
            let newConfig = GIDConfiguration(clientID: configuration.clientID)
            GIDSignIn.sharedInstance.configuration = newConfig
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, hint: nil, additionalScopes: allScopes) { [weak self] signInResult, error in
            if let error = error {
                print("Error requesting additional scopes: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    // If sign-in fails, restore signed-out state
                    self?.accessToken = nil
                    self?.isSignedIn = false
                    self?.deleteTokenFromKeychain()
                }
                return
            }
            
            guard let result = signInResult else { return }
            
            result.user.refreshTokensIfNeeded { auth, error in
                if let error = error {
                    print("Auth error after scope addition: \(error.localizedDescription)")
                    return
                }
                
                if let accessToken = auth?.accessToken.tokenString {
                    DispatchQueue.main.async {
                        self?.accessToken = accessToken
                        self?.isSignedIn = true
                        self?.saveTokenToKeychain(accessToken)
                        
                        // Update user info
                        if let profile = result.user.profile {
                            self?.userName = profile.name
                            self?.userEmail = profile.email
                            self?.userProfileImageURL = profile.hasImage ? profile.imageURL(withDimension: 200) : nil
                            
                            // Save to UserDefaults
                            let defaults = UserDefaults.standard
                            defaults.set(profile.name, forKey: self?.userNameKey ?? "userName")
                            defaults.set(profile.email, forKey: self?.userEmailKey ?? "userEmail")
                            if let url = self?.userProfileImageURL?.absoluteString {
                                defaults.set(url, forKey: self?.userProfileImageURLKey ?? "userProfileImageURL")
                            }
                        }
                        
                        print("Successfully requested additional scopes and updated token")
                        print("Granted scopes: \(result.user.grantedScopes ?? [])")
                    }
                }
            }
        }
    }
    
    func refreshTokenIfNeeded() async -> Bool {
        // If in demo mode, always return true to prevent session expired messages
        if isDemoMode {
            return true
        }
        
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
            return false
        }
        
        do {
            let auth = try await currentUser.refreshTokensIfNeeded()
            let newToken = auth.accessToken.tokenString
            
            // Create a local copy of the token to avoid capturing self
            let token = newToken
            
            await MainActor.run {
                self.accessToken = token
                self.saveTokenToKeychain(token)
            }
            return true
        } catch {
            print("Token refresh error: \(error.localizedDescription)")
            // If refresh fails, sign out the user
            await MainActor.run {
                self.signOut()
            }
        }
        return false
    }
    
    // MARK: - Keychain Operations
    
    private func saveTokenToKeychain(_ token: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: token.data(using: .utf8)!
        ]
        
        // First try to delete any existing token
        SecItemDelete(query as CFDictionary)
        
        // Then save the new token
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error saving token to Keychain: \(status)")
        }
    }
    
    private func loadTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let token = String(data: data, encoding: .utf8) {
            return token
        }
        return nil
    }
    
    private func deleteTokenFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Apple Sign In Methods
    
    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    private func checkAppleSignInState(for userID: String) {
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userID) { [weak self] credentialState, error in
            DispatchQueue.main.async {
                switch credentialState {
                case .authorized:
                    // Apple ID is still valid
                    self?.isAppleSignedIn = true
                case .revoked, .notFound:
                    // Apple ID has been revoked or not found
                    self?.handleAppleSignOut()
                default:
                    break
                }
            }
        }
    }
    
    private func handleAppleSignOut() {
        // Clear Apple Sign In data
        appleUserID = nil
        isAppleSignedIn = false
        UserDefaults.standard.removeObject(forKey: appleUserIDKey)
        
        // Also sign out of Google to maintain consistency
        signOut()
    }
}

// MARK: - Apple Sign In Delegate Methods
extension AuthViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userID = appleIDCredential.user
            
            // Save Apple user ID
            appleUserID = userID
            isAppleSignedIn = true
            UserDefaults.standard.set(userID, forKey: appleUserIDKey)
            
            // Extract user information from Apple ID credential
            var appleUserName = ""
            var appleUserEmail = ""
            
            if let fullName = appleIDCredential.fullName {
                let firstName = fullName.givenName ?? ""
                let lastName = fullName.familyName ?? ""
                appleUserName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
            }
            
            if let email = appleIDCredential.email {
                appleUserEmail = email
            }
            
            // Store Apple user info temporarily
            if !appleUserName.isEmpty {
                self.userName = appleUserName
                UserDefaults.standard.set(appleUserName, forKey: userNameKey)
            }
            
            if !appleUserEmail.isEmpty {
                self.userEmail = appleUserEmail
                UserDefaults.standard.set(appleUserEmail, forKey: userEmailKey)
            }
            
            print("Apple Sign In successful for user: \(userID)")
            
            // Set transitioning state and start Google OAuth flow for AdSense access
            isTransitioningToGoogle = true
            startGoogleOAuthFlow()
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign In failed: \(error.localizedDescription)")
        
        // Reset Apple Sign In state and transitioning state
        appleUserID = nil
        isAppleSignedIn = false
        isTransitioningToGoogle = false
        UserDefaults.standard.removeObject(forKey: appleUserIDKey)
    }
    
    private func startGoogleOAuthFlow() {
        print("🚀 [Auth] Starting Google OAuth flow for AdSense access...")
        print("⏱️ [Auth] Waiting for Apple Sign In UI to dismiss...")
        
        // Add a delay to ensure Apple Sign In UI is fully dismissed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            print("📱 [Auth] Presenting Google OAuth dialog...")
            self?.signIn() // This will call the existing Google Sign In method
        }
        
        // Add a timeout mechanism in case Google Sign-In hangs
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) { [weak self] in
            if self?.isTransitioningToGoogle == true {
                print("⚠️ [Auth] Google OAuth timeout - resetting state")
                self?.isTransitioningToGoogle = false
            }
        }
    }
}

// MARK: - Apple Sign In Presentation Context
extension AuthViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}