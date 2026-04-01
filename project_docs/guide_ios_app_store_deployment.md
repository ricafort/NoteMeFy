# iOS App Store Deployment & RevenueCat Production Guide

This document is a comprehensive, step-by-step guide to taking NoteMeFy from your local Mac to the official Apple App Store, including exactly how to swap your RevenueCat test keys for real production payments.

---

## Phase 1: Apple Developer Portal (The Foundation)
Before Xcode or App Store Connect can do anything, Apple needs to securely know your app exists.

1. Go to [developer.apple.com](https://developer.apple.com) and log in.
2. Navigate to **Certificates, Identifiers & Profiles** -> **Identifiers**.
3. Click the **+** button to register a new **App ID**.
4. Set the **Bundle ID** exactly to: `com.ricafort.notemefy`
5. Scroll down the **Capabilities** list and explicitly check the box for **In-App Purchase**.
6. Save and Register.

---

## Phase 2: App Store Connect & RevenueCat Handshake
Now we create the public-facing store listing and securely link Apple's billing servers to RevenueCat.

### 1. Create the App
1. Go to [App Store Connect](https://appstoreconnect.apple.com).
2. Click **My Apps** -> **+ New App**.
3. Select iOS, name it **NoteMeFy** (or your chosen brand name), and select the Bundle ID you just created (`com.ricafort.notemefy`).

### 2. Create the In-App Purchase
1. On the left sidebar of your App Store Connect app page, scroll down to **Features** -> **In-App Purchases**.
2. Click the **+** to add a new product. 
3. Choose **Non-Consumable** (for lifetime unlocks) or **Auto-Renewing Subscription** (for monthly plans).
4. Set the **Product ID / SKU** to a clear identifier (e.g., `notemefy_pro_lifetime`).
5. Set the price and fill out the display name ("NoteMeFy Pro").

### 3. Generate the Apple Shared Secret
For RevenueCat to verify purchases on your behalf, you must give it a secret "key" to Apple's vault.
1. Still in App Store Connect, go to **App Information**.
2. Scroll down to **App-Specific Shared Secret** and click **Manage/Generate**.
3. Copy this long alphanumeric string securely.

### 4. Link RevenueCat
1. Go to your [RevenueCat Dashboard](https://app.revenuecat.com).
2. Under your Project, add an **App Store app**.
3. Provide the Bundle ID (`com.ricafort.notemefy`) and paste the **App-Specific Shared Secret** you just copied.
4. RevenueCat will instantly generate a public Apple API key (it starts with `appl_...`). **Copy this key.**

---

## Phase 3: Updating the Flutter Codebase
You must replace your development `test_` key with the actual production key so RevenueCat activates the real Apple Pay sheet.

Open `lib/services/pro_upgrade_service.dart` and locate the `_initRevenueCat` function. Modify it to securely assign the production keys:

```dart
      PurchasesConfiguration configuration;
      if (Platform.isIOS) {
        // Your actual Apple App Store RevenueCat key
        configuration = PurchasesConfiguration('appl_YOUR_REAL_KEY_HERE');
      } else if (Platform.isAndroid) {
        // Your actual Google Play Store RevenueCat key
        configuration = PurchasesConfiguration('goog_YOUR_REAL_KEY_HERE');
      }

      await Purchases.configure(configuration);
```
*(Make sure to entirely remove the `test_` key bypass logic we used for local Profile testing earlier).*

---

## Phase 4: Building the Production Archive
With the real keys in place, it's time to physically build the shipping cryptographically-signed app file (`.ipa`).

1. Open your terminal in the `NoteMeFy` root folder.
2. Run the absolute production compiler:
   ```bash
   flutter build ipa
   ```
3. This command takes several minutes. It compiles Dart ahead-of-time (AOT) and strips all debug blockers.
4. When finished, it deposits a `.xcarchive` and an `.ipa` file inside `build/ios/ipa/`.

---

## Phase 5: Uploading and Submitting
1. Open the **Transporter** app (a free app by Apple on the Mac App Store).
2. Log in with your Apple Developer ID.
3. Drag and drop the `.ipa` file from your `build/ios/ipa/` folder directly into the Transporter window and click **Deliver**.
4. Go back to your mobile browser at **App Store Connect** -> **TestFlight**. Wait ~15 minutes for Apple's servers to process the upload. You can invite yourself or testers here to download the exact production app natively!
5. To publish to the world, go to the **Prepare for Submission** page, upload your 3 screenshots, fill out the App Privacy questionnaire, and click **Add for Review**!
