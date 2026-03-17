# 🍎 iOS Simulator Testing Guide: Geofencing & Notifications

This guide provides step-by-step instructions on how to test NoteMeFy's background geofencing and deep-linking notifications on an Apple Silicon (M-series) Mac using the iOS Simulator.

## 1. Prerequisites (Mac Setup)

1. **Install Xcode:** Download and install Xcode from the Mac App Store.
2. **Install Command Line Tools:** Open terminal and run: `xcode-select --install`
3. **Open Xcode Once:** You must open the Xcode application at least once to agree to the terms of service and allow it to install necessary internal components.
4. **Install Cocoapods:** Flutter uses Cocoapods to manage iOS dependencies. Open your Mac's terminal and run:
   ```bash
   sudo gem install cocoapods
   ```
   *(Note: Since you are on an M5 Mac, if you run into ruby/ffi errors, you may need to use Homebrew: `brew install cocoapods`)*

### 🤖 The "AntiGravity" Shortcut
If you have **AntiGravity** installed on your Mac, you can skip steps 2, 3, and 4 above! Simply open the `NoteMeFy` project folder on your Mac, open the AntiGravity chat, and ask:
> *"Hey, please read **project_docs/ios_testing_guide.md** and set up my iOS Simulator environment to run this app."*

AntiGravity will automatically install Cocoapods, verify your Xcode setup, boot up the correct iOS Simulator, and run the app for you.

## 2. Verify iOS Permissions (Info.plist)

Apple has extremely strict location permission rules. Before running the app, ensure your `ios/Runner/Info.plist` file contains the necessary keys. 

Open `ios/Runner/Info.plist` in your code editor and verify these keys exist inside the main `<dict>`:

```xml
<!-- Required for notifications -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>location</string>
    <string>remote-notification</string>
</array>

<!-- Required for Geolocator and Geofencing -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to trigger geofence notes when you arrive at specific places.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location in the background to send you notifications when you arrive at your notes.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location in the background to send you notifications when you arrive at your notes.</string>
```

## 3. Launching the iOS Simulator

1. Open your terminal at the root of the `NoteMeFy` project.
2. Find the ID of your iOS Simulator by running:
   ```bash
   flutter devices
   ```
3. Boot up the iOS Simulator (e.g., iPhone 15 Pro):
   ```bash
   open -a Simulator
   ```
   *(Alternatively, just type `Open iOS Simulator` in VS Code's device selector).*

## 4. Running the App

With the simulator open on your screen, run:

```bash
flutter run
```
*(If prompted, choose the iOS Simulator).*

When the app opens for the first time, it will prompt you for **Notifications** and **Location** permissions.
* **Notifications:** Tap **Allow**.
* **Location:** Tap **Allow While Using App**, and if iOS later prompts to upgrade to **Change to Always Allow**, you MUST accept it for background triggers to work natively.

## 5. How to Fake your GPS Location in the Simulator

Unlike a real phone, the simulator sits still. You have to "teleport" it manually.

1. **Set your "Home" or "Work" in NoteMeFy:**
   * Go to your app's Settings screen and set a Home and Work location (e.g. Home = Eiffel Tower `48.8584, 2.2945`, Work = Apple Park `37.3346, -122.0090`).
2. **Create a Geo-triggered Note:**
   * Go to the Capture screen, write a note, and tag it with "Home".
3. **Teleport away:**
   * Look at your Mac's top menu bar. Click on the **Simulator** app so its menu appears at the very top of your screen.
   * Click **Features** -> **Location** -> **Custom Location...**
   * Enter a Latitude and Longitude far away from your "Home" coordinate (e.g., `0`, `0`).
4. **Trigger the Geofence:**
   * Now, press the physical home button (or swipe up) on the simulator to put the app in the background.
   * Go back to your Mac's top menu bar: **Features** -> **Location** -> **Custom Location...**
   * Enter the EXACT same Latitude and Longitude you used for your "Home" setting within the app.
   * Click **OK**.

## 6. Observing the Result

1. Within seconds of "arriving" at the custom location, a drop-down notification banner should appear at the top of the iOS Simulator screen. 
2. Click the notification banner.
3. The app will snap into the foreground, and the deep-linking logic we built will catch the payload ID, intercept it, and automatically slide up the bottom sheet containing your specific idea!

### Troubleshooting iOS 
* **If the notification doesn't fire:** Ensure you put the app in the background *before* teleporting the simulator. iOS sometimes restricts local notifications from buzzing if the app is already actively driving the screen.
* **Build Errors (`pod install`):** If `flutter run` fails with CocoaPods errors, navigate to the `ios` folder in terminal and run `pod repo update && pod install`, then `cd ..` and try `flutter run` again.
