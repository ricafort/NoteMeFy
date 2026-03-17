# Phase 3: Advanced Notification Deep Linking & Geofence Cleanup

## Title & Overview
**Goal:** Enhance the background location notification system so that tapping a notification securely opens the exact note it references, rather than just dumping the user on the home screen. Furthermore, ensure that deleting a note proactively cleans up its associated OS-level geofence triggers to prevent "ghost" notifications.

---

## Step-by-Step Breakdown

### 1. Payload Passing in Notifications
- **What we did:** Modified `NotificationService` and `GeofenceService` to pass the unique `Note.id` inside the background notification payload.
- **How to replicate it:**
  In `GeofenceService`, when creating the notification, pass the ID:
  ```dart
  await notificationService.showNotification(
    id: geofence.id.hashCode,
    title: 'Location Reminder 📍',
    body: noteContent,
    payload: geofence.id, // <-- Critical addition
  );
  ```
- **Why we did it:** Standard notifications just open the app. By passing a `payload` hidden inside the notification intent, we give the Flutter app the context it needs to route the user to the correct data once it wakes up.

### 2. Cold Start Interception
- **What we did:** Added a check in `main.dart` (`initState`) to look for app launch details.
- **How to replicate it:**
  ```dart
  final details = await ref.read(notificationServiceProvider)
      .flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  
  if (details != null && details.didNotificationLaunchApp) {
    final payload = details.notificationResponse?.payload;
    if (payload != null && navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/review'),
          builder: (context) => ReviewScreen(initialNoteId: payload),
        ),
      );
    }
  }
  ```
- **Why we did it:** If the app is completely swiped away (killed) from memory, the standard `onDidReceiveNotificationResponse` callback might fire *before* the Flutter UI engine has finished rendering the first frame. Using `getNotificationAppLaunchDetails` manually grabs the tap intent *after* the UI is ready to receive it.

### 3. Foreground Reactive Streams (RxDart)
- **What we did:** Implemented an `rxdart` `BehaviorSubject` in `NotificationService` to broadcast notification taps while the app is actively running in memory.
- **How to replicate it:**
  *Add Dependency:* `flutter pub add rxdart`
  *NotificationService:*
  ```dart
  final BehaviorSubject<String?> payloadStream = BehaviorSubject<String?>();
  // Inside the tap callback:
  payloadStream.add(response.payload);
  ```
  *ReviewScreen:*
  ```dart
  _payloadSub = ref.read(notificationServiceProvider).payloadStream.listen((payload) {
    // Open the bottom sheet dynamically without pushing a new screen!
  });
  ```
- **Why we did it:** If the user is already looking at the `ReviewScreen` and taps a notification, pushing *another* `ReviewScreen` via `Navigator.push` stacks the UI infinitely. Streams allow the active, mounted screen to simply react to the event and pop up a targeted bottom sheet over its existing state.

### 4. Route Popping (Preventing Infinite Stacks)
- **What we did:** Used `popUntil` logic when routing to cleanly reset the navigation stack.
- **How to replicate it:**
  ```dart
  navigatorKey!.currentState?.popUntil((route) {
    return route.isFirst || route.settings.name == '/review';
  });
  ```
- **Why we did it:** Tapping notifications while deep inside settings menus or other dialogs would cause weird visual overlaps. `popUntil` acts as a UI reset button, clearing out junk layers before attempting to show the Note.

### 5. Native Geofence Cleanup on Deletion
- **What we did:** Updated `NoteRepository.deleteNote` to explicitly talk to the OS-level geofencing API.
- **How to replicate it:**
  ```dart
  Future<void> deleteNote(String id) async {
    // 1. Delete UI data
    await _box.delete(id);
    // 2. Clear out background OS geofences
    await NativeGeofenceManager.instance.removeGeofenceById(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('note_$id');
  }
  ```
- **Why we did it:** Android Notification Trays and Location Services run completely independent of the Flutter App. Deleting a note from the Hive database does NOT tell Android to stop listening for that location boundary. We must manually deregister it to prevent "ghost" notifications firing for deleted notes.

---

## Quality Assurance
- **Verification:** Ran `flutter run` recursively to test foreground taps, deep background taps, and absolute cold-start taps.
- **Debugging:** Injected `debugPrint` traces to follow the string payload through the `NativeGeofencePlugin` -> `FlutterLocalNotificationsPlugin` -> `StreamListener` pipeline.
- **Linting:** Addressed all IDE warnings regarding misplaced imports and incorrectly typed `AsyncValue` reads during Riverpod stream subscriptions.
