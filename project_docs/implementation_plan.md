# NoteMeFy Implementation Plan

NoteMeFy is a zero-friction, incredibly fast local note-taking mobile application. Its core premise relies on capturing ideas in under 2 seconds and using context-aware triggers (location, time) to resurface them when appropriate.

## User Review Required
- **Location Permissions**: Geofencing technically requires "Always Allow" location permissions on iOS/Android, which can add onboarding friction. We will request these permissions right when the user tries to set their "Home" or "Work" location for the first time.
- **Background Execution**: Real geofencing requires background tasks. To keep the app completely serverless ($0/month) and highly performant, we will use a combination of local Hive storage and device-native geofencing/notification APIs.
- **Theme**: True black (AMOLED) dark theme by default approved.
- **Monetization (No Ads)**: We will build this strictly as a **Freemium** app. Ads will destroy the <0.5s launch time and the pure-privacy App Store approval. The core remains free, but "Routine/Recurring" triggers will be locked behind a "NoteMeFy Pro" paywall.

## Proposed Changes

### Research Validation & App Store Strategy
- **Tech Stack Framework**: Flutter is the chosen cross-platform framework over React Native due to its faster compilation (AOT) to native ARM code, enabling the ~0.8s (or faster) cold start required for the "Zero-UI" feel.
- **Local Database**: Hive is chosen for true Instant-Launch. Since it loads pure Key-Value data synchronously into memory, there is zero asynchronous blocking when the app opens, meaning the keyboard will pop up the millisecond the app renders.
- **App Store / Play Store Appoval (Privacy Clean)**: Even though no data is collected, Apple and Google **mandate** a privacy policy URL. The policy must explicitly state the app is 100% offline and no personal data or location metrics are sent to servers.
  - Zero third-party analytics (no Firebase Analytics) will be included to keep the App Privacy labels completely clean.
- **Hardware Integration (The Action Button)**: Expose iOS App Intents / Android Quick Settings to allow users to bind their physical Action Button or lock-screen shortcut directly to the NoteMeFy capture screen.

### 1. Project Initialization & Foundation
- Setup a new Flutter application (`com.notemefy.app`).
- Add core dependencies: `hive`, `hive_flutter` (local fast storage), `flutter_riverpod` (reactive state management), `geolocator` (location), `flutter_local_notifications` (reminders), `audioplayers` (sound effects), `flutter_vibrate` or `haptic_feedback` (tactile responses).

### 2. UI & Interaction Design (Zero-UI)
- **`lib/main.dart`**: Configure app theme to true black (AMOLED) to save battery and look premium, with a system UI overlay style that hides distractions.
- **`lib/presentation/screens/capture_screen.dart`**: The single primary screen.
  - An invisible, borderless `TextField` that auto-focuses immediately upon app launch (`autofocus: true`) so the keyboard is ready in <0.5s.
  - A subtle indicator at the top: "Swipe down to review notes".
- **`lib/presentation/widgets/smart_trigger_bar.dart`**: Translucent glassmorphic buttons right above the keyboard using `BackdropFilter`.
  - Includes: Home, Work, Tonight, Custom, **and a "★ Pro" icon for Routines**.
- **`lib/presentation/widgets/throw_action_area.dart`**: The gesture area. Swipe up or tap a beautiful button to "throw" the note, invoking haptics and the whoosh sound.
- **`lib/presentation/screens/review_screen.dart`**: 
  - Accessed by swiping down from the Capture Screen.
  - Lists all active and past notes.
  - Allows users to **Start/Stop** active reminders, view history, or delete items.

### 3. Core Logic & Storage
- **`lib/domain/models/note.dart`**: Data model for a note (`id`, `content`, `triggerType`, `triggerValue`, `isActive`, `createdAt`).
- **`lib/data/repositories/note_repository.dart`**: Hive vault for instantaneous reads/writes to ensure zero-lag saving.
- **`lib/services/trigger_service.dart`**: Handles scheduling local OS notifications.
- **`lib/services/pro_upgrade_service.dart`**: Logic for managing the "NoteMeFy Pro" unlock state.

### 4. Polish & Delight
- Implement a heavy "click" haptic upon selecting a trigger.
- Implement a custom "snap" haptic + audio sound effect when the note is "thrown".
- Ensure the app explicitly clears the input to simulate the idea leaving the user's mind so they can close the app instantly.

## Verification Plan

### Automated Tests
- N/A for this initial MVP as we prioritize speed of development and testing via device.

### Manual Verification
- Run the Flutter app on an emulator/device.
- Verify that app opens to a focused text field with the keyboard visible instantly without splash screen delays.
- Type an idea, tap "Tonight", verify haptic click.
- Swipe up to "throw" the note, verify audio plays, haptic snaps, and the screen clears.
- Verify note is saved in the local database and a local notification is scheduled.
