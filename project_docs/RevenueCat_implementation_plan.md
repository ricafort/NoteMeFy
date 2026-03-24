# Goal Description
Integrate RevenueCat into the NoteMeFy app to monetize the application. We will place the Location Geofence features ("Home" and "Work" triggers) behind a premium paywall, while leaving Time/Date scheduled triggers free.

## User Review Required
> [!IMPORTANT]
> To fully test purchases on a physical device, you will need to eventually configure your Apple App Store Connect and Google Play Console accounts inside the RevenueCat Dashboard. For now, we will set up the code structure so that the paywall appears natively in the app.
> 
> **Action item for you:** Please provide your **Public App-Specific API Keys** for iOS and Android from RevenueCat, or let me know if you want me to insert placeholder strings that you can fill in privately later.

## Proposed Changes

### Dependencies
#### [MODIFY] pubspec.yaml
Add `purchases_flutter` and `purchases_ui_flutter` to leverage RevenueCat's Native Paywalls feature, saving us from building a custom purchase UI.

### State & Logic Layer
#### [NEW] lib/services/purchases_service.dart
Create a `PurchasesService` using Riverpod that:
- Initializes the `Purchases` SDK on app startup.
- Listens to `CustomerInfo` updates to determine if the user has the "Premium" entitlement active.
- Exposes a `isPremiumProvider` boolean state for the UI to consume.

#### [MODIFY] lib/main.dart
Call the initialization block for RevenueCat before `runApp`.

### Presentation Layer
#### [MODIFY] lib/presentation/widgets/throw_action_area.dart
When a user taps the "Home" or "Work" trigger buttons, check the `isPremiumProvider`.
- If Premium: Proceed with assigning the location trigger as usual.
- If Free: Intercept the action, and trigger `RevenueCatUI.presentPaywallIfNeeded(...)`.

#### [MODIFY] lib/presentation/screens/review_screen.dart
If a Free user tries to toggle "ON" an older Location note, intercept the toggle and show the same paywall.

## Verification Plan
### Manual Verification
1. We will use `RevenueCatUI.presentPaywallIfNeeded("premium")`. By default, without active subscriptions, tapping the location triggers will slide up the RevenueCat paywall.
2. In the RevenueCat dashboard, we will temporarily structure a test offering. You can log in with a Sandbox Apple ID or Google Test track account to simulate a successful purchase and verify the premium state unlocks Location triggers natively.
