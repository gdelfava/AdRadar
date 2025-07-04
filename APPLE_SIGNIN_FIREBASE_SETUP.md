# Firebase Configuration for Apple Sign In + Google OAuth

## Overview
This guide walks you through configuring Firebase to support the hybrid authentication flow where Apple Sign In handles user authentication and Google OAuth handles AdSense data access.

## 1. Firebase Project Setup

### Step 1: Enable Apple Sign In in Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Navigate to **Authentication** → **Sign-in method**
4. Find **Apple** in the providers list and click on it
5. Toggle **Enable**
6. **Important**: You can leave the configuration mostly default since we're handling Apple Sign In natively in the iOS app

### Step 2: Configure Apple Developer Account
1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Identifiers** → **App IDs**
4. Find your app ID (`com.delteqis.AdRadar`) or create it
5. Edit the app ID and enable **Sign In with Apple** capability
6. Save the changes

### Step 3: Add Service ID (Optional - for Web)
If you plan to support web authentication later:
1. In Apple Developer Portal, create a **Services ID**
2. Configure it with your domain
3. Add the Service ID to Firebase Apple configuration

## 2. Google OAuth Configuration

### Step 1: Google Cloud Console Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (should match your Firebase project)
3. Enable **Google Sign-In API** if not already enabled
4. Navigate to **APIs & Services** → **Credentials**

### Step 2: Configure OAuth Consent Screen
1. Go to **OAuth consent screen**
2. Fill in required information:
   - App name: "AdRadar"
   - User support email
   - Developer contact information
3. Add scopes:
   - `https://www.googleapis.com/auth/adsense.readonly`
   - `https://www.googleapis.com/auth/admob.readonly`
4. Save and continue

### Step 3: OAuth Client ID Configuration
1. Go to **Credentials** → **Create Credentials** → **OAuth 2.0 Client ID**
2. Application type: **iOS**
3. Bundle ID: `com.delteqis.AdRadar`
4. Download the configuration file or copy the Client ID

## 3. iOS App Configuration

### Step 1: Update GoogleService-Info.plist (if using Firebase)
1. Download `GoogleService-Info.plist` from Firebase Console
2. Add it to your Xcode project
3. Ensure it's added to the app target

### Step 2: Update Info.plist
Your `Info.plist` should already have the Google configuration. Verify it contains:

```xml
<key>GIDClientID</key>
<string>YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com</string>
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_GOOGLE_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### Step 3: Xcode Project Settings
1. Open your Xcode project
2. Select your app target
3. Go to **Signing & Capabilities**
4. Add **Sign In with Apple** capability (should be automatically added from entitlements)
5. Verify **App Groups** capability is present

## 4. Testing the Implementation

### Test Apple Sign In
1. Run the app on a device (Apple Sign In doesn't work in simulator for production)
2. Tap "Continue with Apple"
3. Complete Apple authentication
4. Verify that Google OAuth flow starts automatically

### Test Google OAuth
1. Ensure Google OAuth prompts for AdSense/AdMob permissions
2. Verify that access tokens are properly stored
3. Test data fetching from AdSense API

## 5. Production Checklist

### Apple App Store
- [ ] App has **Sign In with Apple** capability enabled
- [ ] Apple Developer account has Sign In with Apple configured for your App ID
- [ ] App handles Apple Sign In revocation properly

### Google APIs
- [ ] OAuth consent screen is configured and verified
- [ ] AdSense API is enabled
- [ ] AdMob API is enabled (if using)
- [ ] Scopes are properly requested in the app

### Firebase
- [ ] Apple Sign In provider is enabled
- [ ] Google Sign In provider is configured (if needed for backup)
- [ ] Security rules are properly configured

## 6. Security Considerations

### Token Management
- Google access tokens are stored securely in Keychain
- Apple user ID is stored in UserDefaults (not sensitive)
- Implement proper token refresh logic

### Privacy
- Apple Sign In provides privacy-focused authentication
- Google OAuth only accesses AdSense data, not personal information
- Clearly communicate data usage to users

## 7. Troubleshooting

### Common Issues
1. **Apple Sign In not working**: Ensure you're testing on a real device, not simulator
2. **Google OAuth fails**: Check that client ID is correct and scopes are properly configured
3. **Token refresh issues**: Verify that Google Sign In configuration is properly initialized

### Debug Steps
1. Check Xcode console for authentication logs
2. Verify network requests are successful
3. Test with different Apple ID accounts
4. Ensure all capabilities are properly configured

## Implementation Notes

The hybrid authentication flow works as follows:
1. User taps "Continue with Apple"
2. Apple Sign In completes and provides user identity
3. App immediately triggers Google OAuth for AdSense access
4. Both authentications are maintained independently
5. Sign out clears both Apple and Google sessions

This approach provides the best user experience while maintaining access to necessary AdSense data. 