# StoreKit 2 In-App Purchases Implementation Guide

## Overview
This guide walks you through the complete implementation of StoreKit 2 in-app purchases for your AdRadar app.

## Files Created/Modified

### New Files Created:
1. `AdRadar/Configuration.storekit` - StoreKit configuration for testing
2. `AdRadar/Core/StoreKitManager.swift` - Core StoreKit 2 manager
3. `AdRadar/Models/PremiumStatusManager.swift` - Premium status management
4. `AdRadar/UI/Components/PremiumUpgradeView.swift` - Premium upgrade UI
5. `AdRadar/UI/Components/PremiumFeatureGate.swift` - Feature gating components

### Modified Files:
1. `AdRadar/AdRadar.entitlements` - Added in-app purchase capability
2. `AdRadar/AdRadar_App.swift` - Initialized StoreKit managers
3. `AdRadar/Views/Settings Screen/SettingsView.swift` - Added premium section

## Setup Steps

### 1. App Store Connect Configuration

1. **Sign in to App Store Connect**
   - Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - Navigate to your AdRadar app

2. **Create In-App Purchase Products**
   - Go to Features → In-App Purchases
   - Create the following products:

   **Auto-Renewable Subscriptions:**
   - Product ID: `com.delteqws.adradar.premium_monthly_sub`
   - Reference Name: Premium Monthly Subscription
   - Subscription Group: Premium Subscriptions
   - Duration: 1 Month
   - Price: $4.99

   - Product ID: `com.delteqws.adradar.premium_yearly_sub`
   - Reference Name: Premium Yearly Subscription  
   - Subscription Group: Premium Subscriptions
   - Duration: 1 Year
   - Price: $49.99

   **Non-Consumable:**
   - Product ID: `com.delteqws.adradar.remove_ads`
   - Reference Name: Remove Ads
   - Price: $2.99

3. **Configure Localizations**
   - Add localizations for each product in all markets you plan to support
   - Include compelling descriptions and clear benefit statements

### 2. Xcode Project Configuration

1. **Enable In-App Purchase Capability**
   - In Xcode, select your project
   - Go to Signing & Capabilities
   - Add "In-App Purchase" capability
   - This is already done via the entitlements file

2. **Configure StoreKit Testing**
   - In Xcode, go to Product → Scheme → Edit Scheme
   - Under "Run" → "Options"
   - Set StoreKit Configuration to "Configuration.storekit"

3. **Add Test User**
   - In App Store Connect, go to Users and Access → Sandbox Testers
   - Create test users for testing purchases

### 3. Testing Your Implementation

#### Local Testing with StoreKit Configuration File

1. **Run the app in simulator or device**
2. **Navigate to Settings → Premium Features**
3. **Tap "Upgrade to Premium"**
4. **Test purchasing flows:**
   - Monthly subscription
   - Yearly subscription  
   - Remove ads purchase
5. **Test restore purchases functionality**

#### Sandbox Testing

1. **Sign out of App Store in Settings**
2. **Run your app on a physical device**
3. **Attempt to make purchases**
4. **Sign in with sandbox test account when prompted**
5. **Complete purchase flows**

### 4. Usage Examples

#### Protecting Premium Features

```swift
// Wrap any view with premium gating
VStack {
    Text("Advanced Analytics")
    // This content will be blurred and show upgrade prompt for non-premium users
}
.premiumGated(feature: .advancedAnalytics)
```

#### Checking Premium Status

```swift
@EnvironmentObject var premiumStatusManager: PremiumStatusManager

var body: some View {
    VStack {
        if premiumStatusManager.isPremiumUser {
            PremiumOnlyView()
        } else {
            FreeUserView()
        }
    }
}
```

#### Adding Premium Badges

```swift
Text("Feature Name")
    .premiumBadge(isVisible: !premiumStatusManager.hasFeature(.advancedAnalytics))
```

### 5. Product IDs Reference

Make sure these match your App Store Connect configuration:

```swift
// Auto-Renewable Subscriptions
"com.delteqws.adradar.premium_monthly_sub"
"com.delteqws.adradar.premium_yearly_sub"

// Non-Consumable
"com.delteqws.adradar.remove_ads"
```

### 6. Key Features Implemented

1. **Automatic Transaction Handling**: Listens for transaction updates automatically
2. **Transaction Verification**: All transactions are cryptographically verified
3. **Subscription Status**: Tracks active subscriptions and renewal status
4. **Restore Purchases**: Users can restore previous purchases
5. **Feature Gating**: Easy-to-use components for protecting premium features
6. **Modern UI**: Beautiful upgrade screens following Apple's Human Interface Guidelines

### 7. Production Checklist

Before releasing to the App Store:

- [ ] Products are approved in App Store Connect
- [ ] All product IDs match between code and App Store Connect
- [ ] Subscription groups are properly configured
- [ ] Privacy policy includes in-app purchase information
- [ ] App description mentions premium features
- [ ] Tested on multiple devices and iOS versions
- [ ] Tested subscription renewal and cancellation flows
- [ ] Verified receipt validation is working
- [ ] All premium features are properly gated

### 8. Monitoring and Analytics

The implementation includes basic analytics tracking:

```swift
// Track when users attempt to use premium features
premiumStatusManager.trackFeatureUsage(.advancedAnalytics)
```

Consider integrating with your analytics service to track:
- Feature usage patterns
- Conversion rates from trial to premium
- Most popular premium features
- Subscription retention rates

### 9. Troubleshooting

#### Common Issues:

1. **Products not loading**: Verify product IDs match App Store Connect exactly
2. **Purchases failing**: Check that test account is signed in and has valid payment method
3. **Transactions not verifying**: Ensure app is built with proper provisioning profile
4. **Subscription status not updating**: Check that subscription groups are configured correctly

#### Debug Tips:

1. Enable StoreKit transaction logs in Console app
2. Check Xcode logs for StoreKit error messages
3. Verify network connectivity for receipt validation
4. Test with both sandbox and production certificates

### 10. Next Steps

After successfully implementing in-app purchases:

1. **Add promotional offers** for subscriptions
2. **Implement subscription cancellation flow**
3. **Add upgrade/downgrade between subscription tiers**
4. **Create paywalls for specific features**
5. **Implement customer support for purchase issues**
6. **Add analytics for purchase funnel optimization**

## Support

For issues with this implementation:
1. Check Apple's StoreKit 2 documentation
2. Review the Console app for detailed error logs
3. Test with multiple devices and account types
4. Verify App Store Connect configuration matches code

Remember to test thoroughly before releasing to ensure a smooth user experience! 