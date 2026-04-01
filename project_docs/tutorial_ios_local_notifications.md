# Tutorial: Achieving Reliable Cold-Start Local Notifications on iOS

## Objective
By the end of this tutorial, you will understand how to correctly configure the `flutter_local_notifications` package for iOS devices. Specifically, you will learn how to guarantee that tapping a local push notification when the app is completely terminated (a "cold start") securely extracts the payload and routes your user to the intended screen without crashing or silent failures.

## Prerequisites
- Basic familiarity with Flutter and Riverpod state management.
- A foundational understanding of Flutter's navigation router (using `Navigator` and `GlobalKey<NavigatorState>`).
- Familiarity with modifying iOS runner files (`AppDelegate.swift`) in Xcode.

---

## The "Why": Why is Cold Start Navigation so Brittle on iOS?
When your Flutter app is fully terminated, the Dart engine is completely shut down. If an iOS scheduled Geofence or Time trigger fires a local notification, it is Apple's native `UNUserNotificationCenter` that displays it. 

When the user taps that banner:
1. iOS boots up your app engine.
2. iOS instantly dispatches a `didReceiveNotificationResponse` signal natively.
3. If Flutter is too slow to build its UI, or if the native iOS bridge isn't explicitly listening for that exact signal during the first milliseconds of boot, **iOS assumes the app cannot handle the payload and throws the data away.**
4. Consequently, Flutter loads the default home screen, entirely ignoring the tapped notification.

To fix this natively and securely, we orchestrate a three-part handshake: A native delegate registration, an explicit pre-UI payload extraction, and a safe post-frame router push.

---

## Code Walkthrough

### 1. Registering the Native Apple Delegates
The `flutter_local_notifications` plugin can only "hear" the iOS click if you explicitly attach it to Apple's native Notification Center. 

In `ios/Runner/AppDelegate.swift`, you must ensure this delegate is assigned inside `didFinishLaunchingWithOptions`:

```swift
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
```
*Why this matters:* Without this exact assignment, Apple natively refuses to pass the tapped payload dictionary over the Flutter bridge on iOS 10+ devices.

### 2. The Pre-UI Sandbox Extraction
If you initialize your notification services inside a standard Widget's `initState`, the Flutter UI has already begun rendering, meaning the native bridge has already fired (and potentially dropped) the payload notification.

Instead, rip the payload directly from the bridge *before* the UI builds in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
*Why this matters:* We are calling `getNotificationAppLaunchDetails()` instantly. Since we haven't asked the plugin to fully `initialize()` yet, it hasn't accidentally consumed or deleted the pending launch parameters, freezing them safely into our string variable. 

### 3. Safe Post-Frame Routing
Now that we caught the data safely, we can't just `push` it inside `initState` because the `Navigator` hasn't mathematically figured out its screen dimensions or routes yet (`MaterialApp` hasn't finished its first layout).

```dart
class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    ref.read(notificationServiceProvider).init();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final payload = widget.initialPayload ?? ref.read(notificationServiceProvider).payloadStream.valueOrNull;

      if (payload != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            settings: const RouteSettings(name: '/review'),
            builder: (context) => ReviewScreen(initialNoteId: payload),
          ),
        );
        ref.read(notificationServiceProvider).payloadStream.add(null);
      }
    });
  }
}
```
*Why this matters:* `addPostFrameCallback` pauses our router logic until exactly 1 microsecond after the very first screen finishes rendering. This guarantees `/review` successfully pushes onto the stack perfectly every time.

---

## Edge Cases & Best Practices

1. **The Black Screen of Death (iOS 14+)**
   - **Pitfall:** Trying to test cold-start notifications via `flutter run` will result in a fatal engine error: *"In iOS 14+, debug mode Flutter apps can only be launched from Flutter tooling..."*
   - **Solution:** Always test cold-start background capabilities using `flutter run --profile -d ios` to compile the engine correctly.

2. **Accidental Duplicate Navigation**
   - **Pitfall:** If you use a `BehaviorSubject` stream to catch payloads while the app is in the background, but also push the same payload during a cold start, your app might push the screen twice.
   - **Solution:** Notice the `payloadStream.add(null);` in the final code block. Clearing the cache ensures the active stream listener doesn't trigger a duplicate push.
