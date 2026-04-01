# Android Google Play Deployment & RevenueCat Production Guide

This document is a comprehensive, step-by-step guide to compiling NoteMeFy for the Google Play Store and securely integrating RevenueCat's Google Play production billing systems.

---

## Phase 1: Google Play Console (The Foundation)
To push an app to millions of Android devices, you must establish its core identity on Google's Developer platform.

1. Go to the [Google Play Console](https://play.google.com/console) and log in.
2. Click **Create App**.
3. Name the app **NoteMeFy**.
4. When prompted for the Application ID / Package Name during setup or upload, it will permanently lock to the `build.gradle` namespace we defined: `com.ricafort.notemefy`.
5. You must complete the initial dashboard tasks: App Content rating, Target Audiences, Data Safety questionnaire, and uploading store graphics.

---

## Phase 2: Connecting RevenueCat & Google Play
Connecting Android billing to RevenueCat requires slightly more backend setup than Apple because Google uses high-security IAM Service Accounts.

### 1. Generate Google Cloud Credentials
RevenueCat needs a secure "robot" account to talk to Google Play on your behalf to verify purchases securely backend-to-backend.
1. Follow RevenueCat's highly specific guide to [Create a Google Play Service Account](https://www.revenuecat.com/docs/creating-play-service-credentials).
2. This involves going to the Google Cloud Console, enabling the **Google Play Android Developer API**, creating a Service Account, granting it the **Financial Data Viewer** and **Manage Orders** roles, and downloading a secure JSON Key file.

### 2. Link RevenueCat
1. Go to your [RevenueCat Dashboard](https://app.revenuecat.com).
2. Under your Project, click **Add New App** -> **Google Play**.
3. Input your package name: `com.ricafort.notemefy`.
4. Upload the **Service Account JSON file** you downloaded from Google Cloud.
5. RevenueCat will generate a public Google Play API key (it starts with `goog_...`). **Copy this key.**

### 3. Create the In-App Product
1. Go to your **Google Play Console** -> Navigate to your app.
2. Scroll to the **Monetize** section -> **In-app products** (or Subscriptions).
3. Create a new product. Set the **Product ID** to match your Apple configuration exactly (e.g., `notemefy_pro_lifetime`).
4. Set the price and activate the product.
5. Back in the RevenueCat dashboard, assign this Product ID to your "NoteMeFy Pro" entitlement.

---

## Phase 3: Updating the Flutter Codebase
Just like iOS, you must replace the sandbox keys in Flutter so RevenueCat triggers the real Google Play billing UI.

Open `lib/services/pro_upgrade_service.dart` and modify the initiation securely:

```dart
      PurchasesConfiguration configuration;
      if (Platform.isIOS) {
        // Your actual Apple App Store key
        configuration = PurchasesConfiguration('appl_YOUR_REAL_KEY_HERE');
      } else if (Platform.isAndroid) {
        // Your actual Google Play Store key
        configuration = PurchasesConfiguration('goog_YOUR_REAL_KEY_HERE');
      }

      await Purchases.configure(configuration);
```

---

## Phase 4: Cryptographic Android Signing
Unlike iOS where Xcode holds your hand, you must generate a secure padlock (Keystore) for Android yourself. Without this, Google rejects your app.

### 1. Create a Keystore
Open your Mac terminal and run this exact command to generate your cryptographic vault:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
*It will ask for a password. Create one, remember it forever, and answer the name/location questions.*

### 2. Link Keystore to Flutter
1. Create a file named `key.properties` inside the `android/` folder of NoteMeFy.
2. Add this text (replacing with the password you just made):
```properties
storePassword=YOUR_PASSWORD_HERE
keyPassword=YOUR_PASSWORD_HERE
keyAlias=upload
storeFile=/Users/francisricafort/upload-keystore.jks
```
3. Open `android/app/build.gradle` and find the `signingConfigs` block. Ensure the `release` config securely parses your `key.properties` file according to the official [Flutter Deployment guidelines](https://docs.flutter.dev/deployment/android#configure-signing-in-gradle).

---

## Phase 5: Building and Uploading
1. Open your terminal in the `NoteMeFy` root folder.
2. Run the Android App Bundle compiler:
   ```bash
   flutter build appbundle
   ```
3. This command takes several minutes and compiles your Dart code against the NDK. It generates a `.aab` file inside `build/app/outputs/bundle/release/app-release.aab`.
4. Go back to the **Google Play Console**.
5. Navigate to **Testing -> Internal Testing** (or Production).
6. Click **Create new release**, and drag and drop your `.aab` file directly into the website.
7. Click Save, fill out your Release Notes, and Rollout! The app will be available to download on the Google Play app shortly.
