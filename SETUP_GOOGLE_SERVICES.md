# Google Services Setup for AdRadar

## ⚠️ SECURITY NOTICE
**Never commit your `GoogleService-Info.plist` file to version control!** This file contains sensitive API keys and credentials.

## Setup Instructions

### 1. Get Your Google Services Configuration

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Go to Project Settings (gear icon)
4. In the "General" tab, find your iOS app
5. Download the `GoogleService-Info.plist` file

### 2. Configure Your Local Environment

1. Copy the template file:
   ```bash
   cp AdRadar/GoogleService-Info.plist.template AdRadar/GoogleService-Info.plist
   ```

2. Open `AdRadar/GoogleService-Info.plist` and replace the placeholder values:
   - `YOUR_API_KEY_HERE` - Your Firebase API key
   - `YOUR_GCM_SENDER_ID_HERE` - Your GCM Sender ID
   - `YOUR_PROJECT_ID_HERE` - Your Firebase project ID
   - `YOUR_GOOGLE_APP_ID_HERE` - Your Google App ID

3. **Important**: Make sure the `BUNDLE_ID` matches your app's bundle identifier: `com.delteqis.AdRadar`

### 3. Required Google Services

This app requires the following Google services:
- **Firebase Authentication** - For user sign-in
- **AdSense Management API** - For AdSense data access
- **AdMob API** - For AdMob analytics (optional)

### 4. Enable Required APIs

In the [Google Cloud Console](https://console.cloud.google.com/):
1. Enable the AdSense Management API
2. Enable the AdMob API (if using AdMob features)
3. Configure OAuth consent screen
4. Add your bundle ID to authorized domains

### 5. Client ID Configuration

The app also reads the `CLIENT_ID` from either:
- `GoogleService-Info.plist` (recommended)
- `Info.plist` (fallback)

Make sure your `CLIENT_ID` is properly configured in your plist files.

## Security Best Practices

1. **Never commit credentials**: The `.gitignore` file is configured to exclude all `GoogleService-Info.plist` files
2. **Use environment-specific configs**: Use different Firebase projects for development, staging, and production
3. **Rotate keys regularly**: Periodically rotate your API keys and update your configuration
4. **Restrict API key usage**: In Google Cloud Console, restrict your API keys to specific APIs and apps

## Troubleshooting

### App Won't Start
- Check that `GoogleService-Info.plist` exists in the `AdRadar/` directory
- Verify all placeholder values have been replaced with real values
- Ensure the file is properly formatted XML

### Authentication Issues
- Verify your bundle ID matches the one configured in Firebase
- Check that the CLIENT_ID is correctly set
- Ensure OAuth consent screen is properly configured

### API Errors
- Verify the required APIs are enabled in Google Cloud Console
- Check that your API keys have the correct permissions
- Ensure your Google account has access to AdSense/AdMob data

## File Structure
```
AdRadar/
├── GoogleService-Info.plist.template  # Template file (committed to git)
├── GoogleService-Info.plist           # Your actual config (ignored by git)
└── Info.plist                         # App configuration
```

## Need Help?

If you encounter issues:
1. Check the [Firebase iOS Setup Guide](https://firebase.google.com/docs/ios/setup)
2. Review the [AdSense Management API documentation](https://developers.google.com/adsense/management)
3. Verify your Google Cloud Console configuration 