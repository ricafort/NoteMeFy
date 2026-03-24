# Tutorial: Integrating RevenueCat Native Paywalls (`purchases_ui_flutter`)

## Objective
By the end of this tutorial, you will understand how to drop a fully compliant, dynamically updating Paywall into a Flutter app using RevenueCat's latest Native Paywall UI package. You will learn how to intercept free actions and show a paywall without writing a single line of custom UI layout code.

## Prerequisites
- **Flutter SDK** & Android Studio / Xcode
- A **RevenueCat Account** with at least one Entitlement created.
- A **Google Play Account** or **Apple Developer Account** (to map real product pricing).

## The "Why"
In the past, developers had to use packages like `in_app_purchase`, map complex JSON products manually, build their own beautiful responsive UI with buttons for "Monthly" / "LifeTime", and then write thousands of lines of logic to validate server receipts to prevent fraud. 

RevenueCat's `purchases_ui_flutter` changes everything. It offloads the entire UI to their servers. You design the Paywall visually on the RevenueCat Dashboard. When your app calls the plugin, it slides up a native Android/iOS sheet showing your exact design, automatically fetching the localized currency prices straight from Apple and Google.

## Code Walkthrough

### 1. The Android Configuration (Crucial!)
Because the Paywall doesn't use Flutter widgets (it uses native OS bottom sheets), Android requires a specific Activity architecture.

**`android/app/src/main/kotlin/.../MainActivity.kt`**
```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

// MISTAKE: class MainActivity : FlutterActivity()
// FIX:
class MainActivity : FlutterFragmentActivity()
```
*If you forget this step, the app will instantly crash with `PlatformException(PAYWALLS_MISSING_WRONG_ACTIVITY)` the second the paywall tries to appear.*

### 2. Initialization & Listening to Entitlements
You must tell RevenueCat who your user is and ask if they have bought your premium product (we called ours "NoteMeFy Pro").

```dart
// We use Riverpod to wrap this state globally!
class ProStatusNotifier extends Notifier<bool> {
  @override
  bool build() {
    _initRevenueCat();
    return false; // Default to free while loading
  }

  Future<void> _initRevenueCat() async {
    // 1. Configure the SDK
    await Purchases.configure(PurchasesConfiguration("appl_xxxxxxxxxx"));
    
    // 2. Listen to ANY purchase events dynamically
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      final isPro = customerInfo.entitlements.all["NoteMeFy Pro"]?.isActive ?? false;
      state = isPro; // Reactively updates the whole UI!
    });
  }
}
```

### 3. Intercepting the Action with the Native Paywall
When the user taps a button that is strictly for Premium users, checking for the upgrade is a one-liner.

```dart
GestureDetector(
  onTap: () async {
    final isPro = ref.read(proUpgradeProvider);
    
    if (!isPro) {
      // 🚀 The Magic One-Liner
      await RevenueCatUI.presentPaywallIfNeeded("NoteMeFy Pro");
      return; 
    }
    
    // Continue with premium logic
    doPremiumFeature();
  }
)
```
Notice we use `presentPaywallIfNeeded()`. If you pass your entitlement string, RevenueCat checks: *Does this user already have 'NoteMeFy Pro'?*
If yes, it does nothing and returns instantly. If no, it smoothly slides up your dashboard-designed paywall!

## Edge Cases & Best Practices

1. **Test API Keys vs Public API Keys**: RevenueCat gives you `test_` keys immediately when signing up. These are great for making sure the sheet pops up, but they *will not show products or prices*. You must link your App Store/Play Store apps inside the dashboard to upgrade to the `appl_` and `goog_` keys.
2. **Sandbox Testing**: Never test purchases in an emulator. Always wire up your device physically, use an Apple Sandbox ID or Google Test Track email, and test the full purchase flow to ensure the webhook gets hit and your Entitlement unlocks correctly.
