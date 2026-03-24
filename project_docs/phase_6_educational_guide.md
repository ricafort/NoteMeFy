# Phase 6: Fixing Android Scheduled Notifications

## Overview
Phase 6 focused on fully debugging and resolving the critical issue with "Custom Time" and "Tonight" scheduled notifications failing to fire. The issue was a combination of missing native Android broadcast receivers, incorrect local timezone initialization, and cached channel configurations failing to notify the user.

## Step-by-Step Breakdown

### 1. Initializing Local Timezones
- **What we did:** Added the `flutter_timezone` package to ensure `flutter_local_notifications` schedules alarms using the user's correct local timezone rather than defaulting to UTC offset.
- **How to replicate it:**
  Run: `flutter pub add flutter_timezone`
  In `notification_service.dart`, add to `init()`:
  ```dart
  tz.initializeTimeZones();
  final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
  ```
- **Why we did it:** Exact alarms are highly dependent on the system clock. Without explicitly initializing `timezone` with local mappings, exact timings provided by the user will be interpreted in the wrong timezone, silently drifting the scheduled date to the future or past.

### 2. Fixing the Android Native Broadcast Receivers
- **What we did:** Injected `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver` into the Android system manifest.
- **How to replicate it:**
  Inside `android/app/src/main/AndroidManifest.xml`, underneath `<application>`, explicitly add:
  ```xml
  <!-- Used by plugin: flutter_local_notifications -->
  <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
  <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
      <intent-filter>
          <action android:name="android.intent.action.BOOT_COMPLETED"/>
          <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
          <action android:name="android.intent.action.QUICKBOOT_POWERON" />
          <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
      </intent-filter>
  </receiver>
  ```
- **Why we did it:** A `zonedSchedule` request tells Android's `AlarmManager` to fire an intent at a specific time. If the target `receiver` of that intent does not functionally exist in the Manifest, Android drops the alarm. This was the primary root cause for notifications failing to physically ring.

### 3. Fixing Channel ID Caching
- **What we did:** Renamed the notification channel ID from `notemefy_channel` to `notemefy_channel_v2`.
- **How to replicate it:**
  In `AndroidNotificationDetails()`, set the first argument to a completely new string: `'notemefy_channel_v2'`.
- **Why we did it:** Android caches notification channel settings (like sound, priority, vibration) forever after their first creation. If standard notifications were accidentally created silently in the past, Android blocks the app from programmatically changing the channel to "High Importance." Changing the ID forces the OS to build a completely fresh, loud channel.

### 4. Preserving the Scheduled Date State
- **What we did:** Updated `ThrowActionArea` to actively capture and write the scheduled `triggerValue` onto the generated `Note` model.
- **How to replicate it:**
  Inside `_handleThrow()`, capture the exact `DateTime` from the notification service and immediately write it:
  ```dart
  var savedNote = note;
  if (savedNote.triggerType == TriggerType.custom) {
     final dt = await ref.read(notificationServiceProvider).scheduleCustomTrigger(savedNote, selectedTime!);
     savedNote = savedNote.copyWith(triggerValue: dt.toIso8601String());
  }
  await ref.read(noteRepositoryProvider).saveNote(savedNote);
  ```
- **Why we did it:** State encapsulation guarantees that visual data (the UI string) matches system state (the background job). If the value is never written to disk, restarting the app means losing the connection to scheduled timings.

### 5. Multi-line UI Responsiveness
- **What we did:** Fixed text overflow errors in the `ReviewScreen` item lists by wrapping the scheduled text in an `Expanded` layout and enforcing natural line breaks.
- **How to replicate it:**
  ```dart
  Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /* Time created */
        Text('Scheduled:\n${dateStr}'), // Two explicit lines
      ]
    )
  )
  ```
- **Why we did it:** Dates and times expand differently depending on the user's localized phone font sizes and settings. Enforcing flexible containers stops `RenderFlex overflowed by N pixels` crashes on small or accessibility-scaled displays.

## Quality Assurance
Verified on a local testing environment via `flutter run`. Ensuring full stop (`q`) was issued to Android builds to wipe the `AndroidManifest.xml` cache. The tests confirmed that positive-only hash-code integers successfully bind `AlarmManager` background processes.
