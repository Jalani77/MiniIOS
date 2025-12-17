# iOS App Store Deployment Setup Guide

This guide explains how to set up automated iOS app deployment using GitHub Actions.

## Prerequisites

### 1. Apple Developer Account
- Enroll in the Apple Developer Program ($99/year)
- URL: https://developer.apple.com/programs/

### 2. Create Xcode Project
**You must do this on a Mac with Xcode installed:**
1. Open Xcode
2. File → New → Project → iOS App
3. Enter:
   - Product Name: HireDayApp
   - Organization Identifier: com.yourcompany.hiredayapp
   - Interface: SwiftUI
   - Language: Swift
4. Copy all Swift files from this repo into the project
5. Commit and push the `.xcodeproj` or `.xcworkspace` file to GitHub

### 3. App Store Connect Setup
1. Go to https://appstoreconnect.apple.com
2. Create a new app
3. Fill in app information, screenshots, descriptions
4. Set bundle identifier (must match your Xcode project)

## Required GitHub Secrets

You need to add these secrets to your GitHub repository:
**Settings → Secrets and variables → Actions → New repository secret**

### Certificate and Provisioning Profile

#### 1. BUILD_CERTIFICATE_BASE64
Your distribution certificate in base64 format.

**To create:**
```bash
# On Mac with Xcode installed:
# 1. Open Keychain Access
# 2. Find your "Apple Distribution" certificate
# 3. Right-click → Export → Save as .p12 file
# 4. Convert to base64:
base64 -i YourCertificate.p12 | pbcopy
# Paste the output as the secret value
```

#### 2. P12_PASSWORD
The password you set when exporting the .p12 certificate.

#### 3. BUILD_PROVISION_PROFILE_BASE64
Your App Store provisioning profile in base64 format.

**To create:**
```bash
# 1. Download from Apple Developer Portal:
#    https://developer.apple.com/account/resources/profiles/
# 2. Download your "App Store" provisioning profile
# 3. Convert to base64:
base64 -i YourProfile.mobileprovision | pbcopy
# Paste the output as the secret value
```

#### 4. KEYCHAIN_PASSWORD
Any secure password for the temporary keychain (e.g., random string).

### Export Options

#### 5. EXPORT_OPTIONS_PLIST
Export options for the IPA in base64 format.

**Create ExportOptions.plist:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.yourcompany.hiredayapp</key>
        <string>YOUR_PROVISIONING_PROFILE_NAME</string>
    </dict>
</dict>
</plist>
```

**Convert to base64:**
```bash
base64 -i ExportOptions.plist | pbcopy
```

### App Store Connect API

#### 6. APP_STORE_CONNECT_API_KEY_ID
The key ID from App Store Connect API.

**To create:**
1. Go to https://appstoreconnect.apple.com/access/api
2. Click "+" to generate a new API key
3. Select "Admin" or "App Manager" role
4. Download the AuthKey_XXXXXX.p8 file
5. Copy the Key ID (shown in the portal)

#### 7. APP_STORE_CONNECT_ISSUER_ID
The Issuer ID from App Store Connect API page.

**Location:** https://appstoreconnect.apple.com/access/api (top right corner)

#### 8. APP_STORE_CONNECT_API_KEY_BASE64
The API key file in base64 format.

```bash
base64 -i AuthKey_XXXXXX.p8 | pbcopy
```

## How to Deploy

Once all secrets are configured:

### Option 1: Push to main branch
```bash
git push origin main
```

### Option 2: Create a version tag
```bash
git tag v1.0.0
git push origin v1.0.0
```

### Option 3: Manual trigger
1. Go to GitHub Actions tab
2. Select "Deploy iOS App to App Store"
3. Click "Run workflow"

## After Deployment

1. Go to App Store Connect
2. Check "TestFlight" for the new build
3. Internal testing automatically begins
4. Submit for external testing (optional)
5. Submit for App Review when ready
6. Release to App Store once approved

## Troubleshooting

- **Build fails:** Check that scheme name matches in workflow file
- **Code signing issues:** Verify certificates and provisioning profiles
- **Upload fails:** Check API key permissions and expiration
- **Missing project:** You must create Xcode project file first on macOS

## Important Notes

- macOS runners on GitHub Actions cost more than Linux runners
- Free tier: 10× usage multiplier (2000 minutes = 200 macOS minutes)
- Paid accounts get more minutes
- Consider using workflow dispatch for manual control to save minutes

## Next Steps

1. Create Xcode project on Mac
2. Push project files to GitHub
3. Add all required secrets
4. Test the workflow
5. Monitor the Actions tab for build status
