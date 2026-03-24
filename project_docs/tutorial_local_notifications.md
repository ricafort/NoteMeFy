# Tutorial: Exact Alarms & Scheduled Notifications in Flutter

## Objective
Learn how to reliably schedule precise, timezone-aware notifications in a Flutter app targeting modern Android 13+ devices, avoiding the dreaded "silent alarm" failures.

## Prerequisites
- Minimum understanding of Riverpod dependency injection.
- Installed Flutter packages:
  - `flutter_local_notifications`
  - `timezone`
  - `flutter_timezone`

## The "Why"
Background execution is heavily restricted on iOS and Android to save battery. If your app promises to remind a user at precisely 1:00 PM tomorrow, you cannot leave the app running or use simple timers; the OS will kill it. Instead, you must surrender the request to the Native OS (`AlarmManager` on Android, `UNUserNotificationCenter` on iOS) and trust the OS to wake your application up exactly when needed.

If misconfigured, these native wake-ups drop silently without crashing the app, making debugging difficult.

## Code Walkthrough

### 1. Bootstrapping Timezones
`flutter_local_notifications` calculates exactly when to wake up based on Unix timestamps mapping to UTC. In order to convert "2 PM" from human-readable local time to an absolute UTC trigger, it must know exactly which regional timezone the phone is currently in.

```dart
// notification_service.dart
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

Future<void> init() async {
  // Load the geographical maps
  tz.initializeTimeZones();
  
  // Ask the OS where we are physically located (e.g. 'America/New_York')
  final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
  
  // Bind localization to the active clock
  tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
}
```

### 2. The Native Android Configuration Requirement
You must register standard broadcast receivers in the `AndroidManifest.xml`. If you do not explicitly register the receiver below `<application>`, the OS will generate the alarm event, realize no one is explicitly listening for it, and drop it.

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
```

Furthermore, an active device reboot immediately wipes all pending Android alarms. The standard boot receiver listens to `BOOT_COMPLETED` from Android and asks the Flutter plugin to recreate them automatically:

```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
    </intent-filter>
</receiver>
```

### 3. Zoned Scheduling Execution
With timezones mapped and XML listeners active, we can schedule the notification itself:

```dart
await plugin.zonedSchedule(
  noteId.hashCode.abs(), // Must be a strictly positive 32-bit integer!
  'Wake Up!', 
  'This is your alarm',
  tz.TZDateTime.from(targetDateTime, tz.local),
  const NotificationDetails(
    android: AndroidNotificationDetails(
      'my_channel_id',
      'Reminders',
      importance: Importance.max,
      priority: Priority.high,
    ),
  ),
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Bypasses standard Android Doze optimizations
  uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
);
```

## Edge Cases & Best Practices
- **Negative `hashCode` Drops:** On Android, using `.hashCode` directly to generate the notification `id` can sometimes produce highly negative integers. Certain versions of native Android Notification plugins silently drop negative integers. Always `.abs()` the unique identifier natively used on the Dart side.
- **Aggressive Doze States:** The `AndroidScheduleMode.exactAllowWhileIdle` forces Android to fire your alarm even if the screen has been off for 12 hours. However, Android requires you to possess `USE_EXACT_ALARM` inside your `AndroidManifest.xml` permissions to access it.
- **Cached Channel States:** If your Android user toggles off vibration in the system settings specifically for your "Reminders" channel, no amount of Dart code will make it vibrate again. You must change the `AndroidNotificationDetails` string identifier (e.g. `'my_channel_v2'`) to start fresh.
