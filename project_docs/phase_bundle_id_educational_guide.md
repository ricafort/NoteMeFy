# Phase Educational Guide: Cross-Platform Bundle ID Restructuring

## Title & Overview
**Goal:** Completely alter the foundational application identifier (Bundle ID / Package Name) across both the iOS and Android compilation targets to match the new all-lowercase format: `com.ricafort.notemefy`. 
**Problem Context:** Applications require uniformly unique identifiers to be published on the Apple App Store and Google Play Console. Flutter uses multiple heavily nested, platform-specific files to declare this identity. Modifying it requires securely rewriting deeply nested native configurations and physically restructuring Kotlin source directories.

---

## Step-by-Step Breakdown

### Step 1: Updating the iOS Project Configuration
**What we did:** We rewrote the `PRODUCT_BUNDLE_IDENTIFIER` value inside the core Xcode `.pbxproj` file tracking the iOS runner.

**How to replicate it:**
Run the following sed replacement command in the terminal to securely swap the strings:
```bash
sed -i '' 's/com.RicafortLabs.NoteMeFy/com.ricafort.notemefy/g' ios/Runner.xcodeproj/project.pbxproj
```

**Why we did it:**
The `project.pbxproj` acts as the definitive source of truth for Xcode. When compiling for Apple devices, Xcode strictly reads this property to determine which Provisioning Profiles and RevenueCat Apple App Store keys can securely authorize the application build.

### Step 2: Updating the Android Build Gradle & Manifests
**What we did:** We redefined the `applicationId` inside the Android Gradle scripts and recursively updated any legacy `AndroidManifest.xml` references.

**How to replicate it:**
Run the following Terminal commands:
```bash
sed -i '' 's/com.RicafortLabs.NoteMeFy/com.ricafort.notemefy/g' android/app/build.gradle
find android/app/src -name "AndroidManifest.xml" -exec sed -i '' 's/com.RicafortLabs.NoteMeFy/com.ricafort.notemefy/g' {} +
```

**Why we did it:**
The `build.gradle` defines the ultimate `namespace` and unique application identifier passed securely to the Google Play Store. It ensures Firebase, RevenueCat, and Android OS recognize exactly who the app belongs to.

### Step 3: Physically Moving the Kotlin Native Directory
**What we did:** We refactored the native Android `MainActivity.kt` file into an entirely new folder hierarchy strictly matching the new domain structure, and altered its internal package declaration.

**How to replicate it:**
Run these directory migration commands:
```bash
# Rename the internal Kotlin package declaration
sed -i '' 's/com.RicafortLabs.NoteMeFy/com.ricafort.notemefy/g' android/app/src/main/kotlin/com/RicafortLabs/NoteMeFy/MainActivity.kt

# Physically construct the new lowercase directory path
mkdir -p android/app/src/main/kotlin/com/ricafort/notemefy

# Move the Kotlin driver file into the new path
mv android/app/src/main/kotlin/com/RicafortLabs/NoteMeFy/MainActivity.kt android/app/src/main/kotlin/com/ricafort/notemefy/

# Safely delete the old unused directory structure
rm -rf android/app/src/main/kotlin/com/RicafortLabs
```

**Why we did it:**
Unlike iOS, Java and Kotlin enforce a strict structural rule where a file's `package com.x.y` declaration must functionally mirror the exact hard drive folders it sits inside. Leaving `MainActivity.kt` inside the old capitalized directory while renaming the package creates severe native Android build exceptions (`ClassNotFoundException`).

---

## Quality Assurance
To effectively verify this complete identifier transformation:
1. Checked Android project compilation paths locally via regex.
2. The exact same lowercase bundle identity (`com.ricafort.notemefy`) is confirmed across both `build.gradle` and `project.pbxproj`.
3. Verified the Git tree explicitly tracks the deleted legacy files vs. the newly constructed Kotlin structure before pushing back to `origin/main`.
