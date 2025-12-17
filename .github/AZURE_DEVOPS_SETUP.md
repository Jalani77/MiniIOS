# Azure DevOps iOS Deployment Setup

Deploy your iOS app to the App Store using Azure DevOps with Microsoft-hosted macOS agents. **No Mac required!**

## Prerequisites

### 1. Accounts Required
- **Apple Developer Account** ($99/year) - https://developer.apple.com/programs/
- **Azure DevOps Account** (Free tier available) - https://dev.azure.com/

### 2. Create Xcode Project First
**This is the one step that requires a Mac or Mac in the cloud:**
1. Access a Mac (physical, cloud Mac, or friend's Mac for 30 minutes)
2. Open Xcode → New Project → iOS App
3. Product Name: HireDayApp
4. Bundle ID: com.yourcompany.hiredayapp (must be unique)
5. Add all Swift files from this repo
6. Push `.xcodeproj` or `.xcworkspace` to GitHub
7. **You're done with the Mac!** Everything else is automated.

## Azure DevOps Setup

### Step 1: Create Azure DevOps Project
1. Go to https://dev.azure.com/
2. Create new organization (if needed)
3. Create new project: "HireDayApp"

### Step 2: Connect GitHub Repository
1. In Azure DevOps: **Pipelines** → **New Pipeline**
2. Select **GitHub**
3. Authenticate with GitHub
4. Select repository: `Jalani77/MiniIOS`
5. Choose **Existing Azure Pipelines YAML file**
6. Select `/azure-pipelines.yml`

### Step 3: Upload Certificates & Profiles

#### Get Apple Distribution Certificate
1. On a Mac with Xcode:
   - Open **Keychain Access**
   - Find "Apple Distribution" certificate
   - Right-click → **Export** → Save as `.p12`
   - Set a password (remember it!)

2. In Azure DevOps:
   - Go to **Pipelines** → **Library** → **Secure files**
   - Click **+ Secure file**
   - Upload your `.p12` file
   - Name it: `AppleDistributionCertificate.p12`

#### Get Provisioning Profile
1. Go to https://developer.apple.com/account/resources/profiles/
2. Create new **App Store** provisioning profile
3. Select your App ID
4. Select distribution certificate
5. Download the `.mobileprovision` file

6. In Azure DevOps:
   - **Pipelines** → **Library** → **Secure files**
   - Upload provisioning profile
   - Name it: `AppStoreProvisioningProfile.mobileprovision`

### Step 4: Configure Variables

In Azure DevOps: **Pipelines** → **Library** → **Variable groups** → **+ Variable group**

Create variable group named: `iOS-Deployment-Variables`

Add these variables:

| Variable Name | Value | Secret? |
|--------------|-------|---------|
| P12_PASSWORD | Your .p12 password | ✓ Yes |
| KEYCHAIN_PASSWORD | Any secure password | ✓ Yes |
| APPLE_SIGNING_IDENTITY | Apple Distribution: Your Name (Team ID) | No |
| APPLE_PROV_PROFILE_UUID | UUID from provisioning profile | No |
| APPLE_TEAM_ID | Your 10-character Team ID | No |
| APPLE_TEAM_NAME | Your team/company name | No |
| APP_STORE_CONNECT_API_KEY_ID | API Key ID (from next step) | ✓ Yes |
| APP_STORE_CONNECT_ISSUER_ID | Issuer ID | No |

**To find Provisioning Profile UUID:**
```bash
# On Mac or in terminal with the .mobileprovision file:
security cms -D -i AppStoreProvisioningProfile.mobileprovision | grep UUID -A1
```

### Step 5: App Store Connect API Key

1. Go to https://appstoreconnect.apple.com/access/api
2. Click **+** to create new key
3. Name: "Azure DevOps"
4. Access: **Admin** or **App Manager**
5. Click **Generate**
6. **Download** the `AuthKey_XXXXXX.p8` file (only chance!)
7. Note the **Key ID** and **Issuer ID**

In Azure DevOps:
- Upload `.p8` file to **Secure files**
- Add Key ID and Issuer ID to variables

### Step 6: Update Configuration Files

#### Update ExportOptions.plist
Replace placeholders in `ExportOptions.plist`:
- `YOUR_TEAM_ID` → Your Apple Team ID
- `com.yourcompany.hiredayapp` → Your bundle ID
- `YOUR_PROVISIONING_PROFILE_NAME` → Name of your provisioning profile

#### Update azure-pipelines.yml
If using workspace instead of project:
- Change `workspacePath` variable
- Or change to use `projectPath` if using `.xcodeproj`

### Step 7: Create Service Connection (Optional)

For automatic uploads:
1. **Project Settings** → **Service connections**
2. Click **New service connection**
3. Select **App Store**
4. Fill in:
   - Connection name: `AppStoreConnection`
   - Authentication method: API Key
   - Upload your `.p8` file
   - Enter Key ID and Issuer ID
5. Save

### Step 8: Link Variable Group to Pipeline

1. Edit your pipeline
2. Click **Variables** → **Variable groups**
3. Link `iOS-Deployment-Variables`
4. Save

## Running the Pipeline

### Automatic Trigger
Push to `main` branch or create a version tag:
```bash
git add .
git commit -m "Update app"
git push origin main

# OR create version tag
git tag v1.0.0
git push origin v1.0.0
```

### Manual Trigger
1. Go to **Pipelines**
2. Select your pipeline
3. Click **Run pipeline**
4. Choose branch and click **Run**

## Pipeline Stages

### Stage 1: Build
1. Installs certificate and provisioning profile
2. Builds the iOS app
3. Creates archive
4. Generates .ipa file
5. Publishes as artifact

### Stage 2: Deploy
1. Downloads .ipa artifact
2. Uploads to App Store Connect
3. App appears in TestFlight
4. Ready for testing and submission

## After Deployment

1. Go to https://appstoreconnect.apple.com
2. Check **TestFlight** tab
3. New build should appear (processing ~10-20 minutes)
4. Add internal testers (automatic)
5. Add external testers (optional, requires review)
6. Submit for App Review when ready
7. Release to App Store once approved

## Troubleshooting

### Build Fails
- Verify scheme name matches in `azure-pipelines.yml`
- Check if using workspace or project file
- Ensure Xcode project is properly configured

### Code Signing Errors
- Verify certificate is not expired
- Check provisioning profile includes correct devices/entitlements
- Ensure bundle ID matches in Xcode, provisioning profile, and App Store

### Upload Fails
- Check API key permissions and expiration
- Verify bundle ID is registered in App Store Connect
- Ensure app record exists in App Store Connect

### Variable Not Found
- Ensure variable group is linked to pipeline
- Check variable names match exactly
- Secret variables must be marked as such

## Cost Information

### Azure DevOps (Free Tier)
- 1 free Microsoft-hosted agent
- 1,800 minutes/month for private repos
- Unlimited for public repos
- macOS agents available

### Paid Plans
- Additional parallel jobs: $40/month each
- More minutes for private repos
- Priority queue access

## Advantages over GitHub Actions

✓ **More free macOS build minutes**
✓ **Built-in secure file storage**
✓ **Visual pipeline designer available**
✓ **Better integration with Microsoft ecosystem**
✓ **Service connections for App Store**

## Next Steps

1. ✅ Create Xcode project (one-time, requires Mac)
2. ✅ Set up Azure DevOps project
3. ✅ Upload certificates and profiles
4. ✅ Configure variables
5. ✅ Update configuration files
6. ✅ Run pipeline
7. ✅ Monitor build and deployment
8. ✅ Test in TestFlight
9. ✅ Submit for App Review

## Additional Resources

- [Azure DevOps iOS Documentation](https://docs.microsoft.com/azure/devops/pipelines/ecosystems/xcode)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [Xcode Build Settings](https://developer.apple.com/documentation/xcode)
- [TestFlight Beta Testing](https://developer.apple.com/testflight/)
