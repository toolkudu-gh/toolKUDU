# ToolKUDU Deployment Guide

This guide covers deploying ToolKUDU to AWS and publishing to the Apple App Store and Google Play Store.

---

## Prerequisites

- AWS Account with appropriate IAM permissions
- Node.js 20.x installed
- Flutter SDK 3.10+ installed
- Apple Developer Account ($99/year) for iOS App Store
- Google Play Developer Account ($25 one-time) for Android
- Domain name (your purchased domain)

---

## Part 1: AWS Backend Deployment

### Step 1: Install Required Tools

```bash
# Install AWS CLI
# Windows: Download from https://aws.amazon.com/cli/
# Mac: brew install awscli

# Configure AWS CLI
aws configure
# Enter your AWS Access Key ID, Secret Access Key, region (us-east-1)

# Install Serverless Framework
npm install -g serverless
```

### Step 2: Set Up Environment Variables

Create a `.env` file in `backend/infrastructure/`:

```env
# Database
DB_PASSWORD=your_secure_password_here

# VPC (create or use existing)
VPC_ID=vpc-xxxxxxxxx
SUBNET_1=subnet-xxxxxxxx
SUBNET_2=subnet-yyyyyyyy

# Stage (dev, staging, prod)
STAGE=prod
```

### Step 3: Deploy Infrastructure

```bash
cd backend/infrastructure

# Deploy to production
serverless deploy --stage prod

# Note the outputs - you'll need:
# - UserPoolId
# - UserPoolClientId
# - S3 Bucket name
# - API Gateway URL
```

### Step 4: Initialize Database

```bash
# Connect to RDS instance and run schema
psql -h <rds-endpoint> -U toolkudu -d toolkudu -f ../shared/db/schema.sql
```

### Step 5: Deploy Backend Services

```bash
# Deploy each service
cd ../services/user-service
serverless deploy --stage prod

cd ../tool-service
serverless deploy --stage prod

cd ../sharing-service
serverless deploy --stage prod

cd ../location-service
serverless deploy --stage prod
```

---

## Part 2: Domain & SSL Setup

### Step 1: Configure Route 53

1. Go to AWS Route 53
2. Create a hosted zone for your domain (e.g., `toolkudu.com`)
3. Update your domain registrar's nameservers to Route 53's nameservers

### Step 2: Request SSL Certificate

1. Go to AWS Certificate Manager (ACM)
2. Request a public certificate for:
   - `toolkudu.com`
   - `*.toolkudu.com`
   - `api.toolkudu.com`
3. Validate via DNS (add CNAME records to Route 53)

### Step 3: Set Up API Gateway Custom Domain

1. Go to API Gateway > Custom Domain Names
2. Create domain: `api.toolkudu.com`
3. Select your ACM certificate
4. Add API mapping to your deployed API
5. Create Route 53 A record (alias) pointing to the API Gateway domain

### Step 4: Set Up CloudFront for Web App (Optional)

For hosting the Flutter web app:

```bash
# Build Flutter web
cd frontend
flutter build web --release

# Create S3 bucket for web hosting
aws s3 mb s3://toolkudu-web-prod

# Upload web build
aws s3 sync build/web s3://toolkudu-web-prod --acl public-read

# Create CloudFront distribution pointing to S3
# Configure custom domain and SSL certificate
```

---

## Part 3: Configure Cognito for Production

### Step 1: Set Up Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable Google Sign-In API
4. Configure OAuth consent screen
5. Create OAuth 2.0 credentials:
   - Web client (for web app)
   - iOS client (for iOS app)
   - Android client (for Android app)

### Step 2: Add Google as Identity Provider in Cognito

1. Go to AWS Cognito > User Pools > Your pool
2. Sign-in experience > Federated identity provider sign-in
3. Add Google as a provider
4. Enter your Google Client ID and Secret

### Step 3: Update Frontend Configuration

Update `frontend/lib/core/config/cognito_config.dart`:

```dart
class CognitoConfig {
  static const String userPoolId = 'us-east-1_XXXXXXXX';
  static const String clientId = 'your-app-client-id';
  static const String region = 'us-east-1';
  static const String identityPoolId = 'us-east-1:xxxxxxxx-xxxx-xxxx-xxxx';
  static const String googleClientId = 'your-google-client-id.apps.googleusercontent.com';
  static const String apiBaseUrl = 'https://api.toolkudu.com';
}
```

---

## Part 4: iOS App Store Deployment

### Step 1: Configure iOS Project

```bash
cd frontend/ios

# Update Bundle Identifier in Xcode
# Open ios/Runner.xcworkspace in Xcode
# Set Bundle Identifier: com.yourcompany.toolkudu
# Set Display Name: ToolKUDU
# Set Version and Build number
```

### Step 2: Configure Google Sign-In for iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
<key>GIDClientID</key>
<string>YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com</string>
```

### Step 3: Create App Store Connect Entry

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. My Apps > + > New App
3. Fill in app information:
   - Name: ToolKUDU
   - Primary Language
   - Bundle ID
   - SKU

### Step 4: Build and Upload

```bash
cd frontend

# Build iOS release
flutter build ipa --release

# The IPA file will be in build/ios/ipa/

# Upload using Transporter app or:
xcrun altool --upload-app --type ios --file build/ios/ipa/toolkudu.ipa --apiKey YOUR_KEY --apiIssuer YOUR_ISSUER
```

### Step 5: Submit for Review

1. In App Store Connect, complete all metadata:
   - Screenshots (6.5" and 5.5" iPhone)
   - App description
   - Keywords
   - Privacy Policy URL
   - Support URL
2. Select build
3. Submit for review

---

## Part 5: Google Play Store Deployment

### Step 1: Configure Android Project

Update `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        applicationId "com.yourcompany.toolkudu"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

### Step 2: Create Signing Key

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties`:

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

### Step 3: Configure Google Sign-In for Android

1. Get SHA-1 fingerprint:
   ```bash
   keytool -list -v -keystore upload-keystore.jks -alias upload
   ```
2. Add SHA-1 to Google Cloud Console > Credentials > Android Client

### Step 4: Build Release APK/AAB

```bash
cd frontend

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release

# Or build APK
flutter build apk --release --split-per-abi
```

### Step 5: Create Play Console Entry

1. Go to [Google Play Console](https://play.google.com/console)
2. Create app > Enter app details
3. Set up your app:
   - Store listing (title, description, screenshots)
   - Content rating questionnaire
   - Target audience
   - Privacy policy

### Step 6: Upload and Release

1. Production > Create new release
2. Upload AAB file from `build/app/outputs/bundle/release/`
3. Add release notes
4. Review and roll out

---

## Part 6: Web App Deployment

### Option A: AWS Amplify (Recommended)

```bash
# Install Amplify CLI
npm install -g @aws-amplify/cli

# Initialize Amplify
cd frontend
amplify init

# Add hosting
amplify add hosting
# Choose: Hosting with Amplify Console
# Choose: Continuous deployment

# Connect to your Git repository in Amplify Console
# Amplify will auto-deploy on push
```

### Option B: S3 + CloudFront

```bash
# Build web
flutter build web --release --web-renderer canvaskit

# Deploy to S3
aws s3 sync build/web s3://your-web-bucket --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/*"
```

---

## Part 7: Environment Configuration Summary

### Production Environment Variables

**Backend (.env)**:
```env
STAGE=prod
AWS_REGION=us-east-1
DB_HOST=your-rds-endpoint
DB_NAME=toolkudu
DB_USER=toolkudu
DB_PASSWORD=secure_password
```

**Frontend (build arguments)**:
```bash
flutter build web \
  --dart-define=COGNITO_USER_POOL_ID=us-east-1_XXXXXXX \
  --dart-define=COGNITO_CLIENT_ID=xxxxxxxxx \
  --dart-define=AWS_REGION=us-east-1 \
  --dart-define=API_BASE_URL=https://api.toolkudu.com \
  --dart-define=GOOGLE_CLIENT_ID=xxxxxx.apps.googleusercontent.com
```

---

## Part 8: Post-Deployment Checklist

- [ ] Backend services responding correctly
- [ ] Database migrations applied
- [ ] Cognito user pool configured
- [ ] Google Sign-In working
- [ ] Custom domain SSL working
- [ ] API Gateway custom domain configured
- [ ] iOS app submitted and approved
- [ ] Android app submitted and approved
- [ ] Web app deployed and accessible
- [ ] Monitoring and logging set up (CloudWatch)
- [ ] Error tracking configured (optional: Sentry)

---

## Troubleshooting

### Common Issues

1. **CORS errors**: Check API Gateway CORS configuration
2. **Authentication failures**: Verify Cognito config matches deployment
3. **Database connection errors**: Check security groups allow Lambda access to RDS
4. **iOS build fails**: Ensure certificates and provisioning profiles are valid
5. **Android signing issues**: Verify key.properties path and passwords

### Useful Commands

```bash
# Check serverless deployment status
serverless info --stage prod

# View Lambda logs
serverless logs -f functionName --stage prod

# Test API endpoint
curl https://api.toolkudu.com/health
```

---

## Cost Estimation (Monthly)

| Service | Estimated Cost |
|---------|----------------|
| RDS (t3.micro) | ~$15-20 |
| Lambda | ~$0-5 (free tier) |
| API Gateway | ~$3-10 |
| S3 | ~$1-5 |
| CloudFront | ~$1-10 |
| Cognito | Free (up to 50k MAU) |
| Route 53 | ~$0.50/zone |
| **Total** | **~$25-50/month** |

---

## Support

For deployment issues, check:
- AWS CloudWatch Logs
- Serverless Framework documentation
- Flutter deployment guides
