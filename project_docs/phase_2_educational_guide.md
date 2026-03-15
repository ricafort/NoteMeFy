# Phase 2 Educational Guide: Native Background Geofencing & Riverpod Settings

## Overview
In this development phase, we tackled a common mobile development challenge: executing background tasks while the app is completely terminated. We replaced a battery-draining foreground-service geofence with OS-native Intents. Additionally, we implemented a customizable "Tonight" time selector using Modern Riverpod `Notifier` patterns.

---

## Step-by-Step Breakdown

### 1. Migrating to Native OS Geofencing

**What we did:** 
We replaced the `geofence_service` package with `native_geofence`. This allowed us to remove the persistent foreground notification and instead rely on the Android `GeofencingClient` to wake up our app only when crossing a boundary.

**How to replicate it:**
1. Add the package: `flutter pub add native_geofence`.
2. Update the `AndroidManifest.xml` to declare the background receivers:
```xml
<receiver android:name="com.chunkytofustudios.native_geofence.receivers.NativeGeofenceBroadcastReceiver" android:exported="true"/>
<receiver android:name="com.chunkytofustudios.native_geofence.receivers.NativeGeofenceRebootBroadcastReceiver" android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"></action>
    </intent-filter>
</receiver>
```
3. Initialize the plugin in `main.dart` immediately at startup:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NativeGeofenceManager.instance.initialize();
  // ... run app
}
```
4. Define a top-level `@pragma('vm:entry-point')` callback to handle the background wake-up intent.

**Why we did it:** 
Foreground services (constantly running a background isolate to poll GPS) drain the user's battery and clutter the notification tray. The OS native mechanisms (`GeofencingClient` on Android, `CLLocationManager` on iOS) track locations at the hardware level, drawing virtually zero battery. They wake the app up natively when the geofence perimeter is breached.

---

### 2. Bypassing UI Threads in Background Isolates

**What we did:** 
We modified the `NotificationService` to conditionally skip requesting system permission dialogs when the app is awoken in the background.

**How to replicate it:**
```dart
  Future<void> init({bool isBackground = false}) async {
    tz.initializeTimeZones();
    
    // UI Dialogs crash background isolates! Skip them.
    if (!isBackground) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }
```

**Why we did it:** 
When the Android OS wakes up a Flutter background isolate to fire a geofence, there is no UI attached (`FlutterRenderer: Width is zero`). If the background thread attempts to launch a UI permission dialog, the OS throws an exception and kills the isolate instantly. Building "Headless-Safe" services is a fundamental mobile engineering architecture pattern.

---

### 3. Modern Riverpod Notifier Providers

**What we did:** 
We upgraded the `SettingsScreen`'s state management to use Riverpod 2.0's `NotifierProvider` instead of the legacy `StateNotifier`.

**How to replicate it:**
```dart
// Modern Riverpod 2.0 Notifier syntax
class TonightTimeNotifier extends Notifier<TimeOfDay> {
  @override
  TimeOfDay build() {
    // Read from SharedPreferences synchronously (if cached) or set default
    return const TimeOfDay(hour: 20, minute: 0);
  }

  void updateTime(TimeOfDay newTime) {
    state = newTime; // Triggers UI rebuild automatically
  }
}

final tonightTimeProvider = NotifierProvider<TonightTimeNotifier, TimeOfDay>(() {
  return TonightTimeNotifier();
});
```

**Why we did it:** 
`StateNotifier` is officially deprecated in modern `flutter_riverpod`. The `Notifier` pattern provides a safer `build()` method lifecycle for synchronous initialization and drastically reduces boilerplate syntax.

---

## Quality Assurance
* **Native Crash Forensics:** Captured bare-metal Android Zygote logs via `adb logcat` to precisely identify that the background thread was explicitly receiving a `Signal 9 (Killed)` from the OS scheduler upon waking.
* **Geofence Emulator Spoofing:** Simulated GPS boundaries to verify entry-events without requiring physical movement.
* **Linting:** Addressed all `dart analyze` warnings to ensure clean syntax.
