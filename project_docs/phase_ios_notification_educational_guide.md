# Phase Educational Guide: iOS Notification Cold Start Routing

## Title & Overview
**Goal:** Achieve reliable navigation routing when an iOS user taps a local push notification while the app is completely terminated (Cold Start). 
**Problem Context:** By default, `flutter_local_notifications` has a severe race condition on iOS 10+. Without strict native delegate registration and extremely early initialization (i.e., inside `main()`), the iOS native system silently drops the notification payload, dumping users onto the default app home screen instead of the exact navigated route they were meant to see.

---

## Step-by-Step Breakdown

### Step 1: Injecting Native iOS Delegates
**What we did:**
We modified the `AppDelegate.swift` file for iOS to firmly register the `UNUserNotificationCenter` delegate. We also registered the `FlutterLocalNotificationsPlugin` callback mechanism explicitly so that background isolates (like geofences) can properly interact with the system notifications.

**How to replicate it:**
Open `ios/Runner/AppDelegate.swift` and insert the plugin registries inside your `didFinishLaunchingWithOptions` function:

```swift
override func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    // Other integrations...
    
    // 1. Required for background isolate scheduled notifications
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
        GeneratedPluginRegistrant.register(with: registry)
    }
    
    // 2. Required to capture tapped payload responses on iOS 10+
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}
```

**Why we did it:**
If the Flutter plugin doesn't intercept the notification payload identically as the native OS does, the iOS system strictly assumes the app has no capacity to process the tap dynamically, and it simply wipes the payload from memory upon launching the app engine. Without this code, local iOS notifications essentially function as completely empty shortcut icons.

### Step 2: Extracting Launch Details Before `runApp`
**What we did:**
We extracted the `getNotificationAppLaunchDetails` directly inside `main.dart` *before* the Flutter application UI boots up, rather than inside a Widget's `initState`.

**How to replicate it:**
Modify your `main.dart` file as follows:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Extract the launch payload BEFORE initialize() is ever natively called!
  String? initialPayload;
  try {
    final details = await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp && details.notificationResponse != null) {
      initialPayload = details.notificationResponse?.payload;
    }
  } catch (e) {
    debugPrint('Failed to get launch details early: $e');
  }

  runApp(
    ProviderScope(
      child: MyApp(initialPayload: initialPayload),
    ),
  );
}
```

**Why we did it:**
If you wait until `initState` to check for this payload, and concurrently call `.initialize()` on the plugin, iOS will immediately consume the pending payload and empty the cache. By executing this as the very first thread inside `main()`, we seize the native data string firmly before any routing or asynchronous UI initializations could destroy it.

### Step 3: Secure Post-Frame Navigation Routing
**What we did:**
We collected the `initialPayload` passed down from `main()` and told the `Navigator` to push the user to the `ReviewScreen`, strictly waiting until the first UI frame finishes drawing so it doesn't crash on an unmounted router.

**How to replicate it:**
Inside `_MyAppState` in your `main.dart`:

```dart
class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    ref.read(notificationServiceProvider).init();

    // Use a post-frame callback to ensure the Navigator is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final payload = widget.initialPayload ?? ref.read(notificationServiceProvider).payloadStream.valueOrNull;

      if (payload != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            settings: const RouteSettings(name: '/review'),
            builder: (context) => ReviewScreen(initialNoteId: payload),
          ),
        );
        // Clear stream to prevent loop logic
        ref.read(notificationServiceProvider).payloadStream.add(null);
      }
    });
  }
}
```

**Why we did it:**
Attempting to push a route before `MaterialApp` has executed its initial build throws critical navigation assertion errors. `addPostFrameCallback` is the safest, most bulletproof method inside Flutter to hook into the immediate lifecycle moment exactly one millisecond after the app's foundation is structurally solid.

---

## Quality Assurance
To effectively verify these notifications without being blocked natively by Apple's debug limitations on iOS 14+:
1. We compiled the app specifically targeting AOT compilation via the terminal using `flutter run --profile -d ios`.
2. A temporary override was added to stop `purchases_flutter` from fatally crashing the Profile build when a `test_` API key was evaluated.
3. The app was fully killed from the background app switcher, triggered manually via Geofence entry/exit, and tested to ensure it routed successfully to the exact note via the `ReviewScreen` natively.
