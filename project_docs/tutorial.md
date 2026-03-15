# 🎒 NoteMeFy: Beginner's Pocket Guide

Hey there! Welcome to the source code of NoteMeFy. 
If you are new to Flutter, this guide is your "Day 1" map to how this app works.

## 🧱 The Language Foundation
- **Flutter & Dart:** We use Dart (a fast, typed language by Google) wrapped in Flutter. Think of Flutter like a box of highly customizable Lego blocks for building user interfaces.

## 🚀 3 Key Concepts to Learn
1. **Widgets are Everything:** In Flutter, a button is a Widget, text is a Widget, and even the "Padding" around the text is a Widget! They nest inside each other like Russian Matryoshka dolls.
2. **State Management (Riverpod):** If the UI is the "car", state management is the "engine". Riverpod connects our data (like "Is the user a Pro subscriber?") to the visual screen.
3. **Isolates (Background Magic):** Mobile phones pause an app when you close it. "Isolates" are special parallel workers that let us run code (like checking your GPS location) while the app is seemingly asleep!

## 🗺️ Project Map
Here is where the important stuff lives:
*   `lib/main.dart` -> The starting line. Where the app boots up.
*   `lib/presentation/` -> The visual Legos. 
    *   `screens/capture_screen.dart` -> The main typing screen.
    *   `widgets/smart_trigger_bar.dart` -> The row of buttons (Home, Work, Pro).
*   `lib/services/` -> The brains of the operation.
    *   `geofence_service.dart` -> Talks to the phone's GPS.
    *   `pro_upgrade_service.dart` -> Checks if you paid for the app.

## ⚡ How to Run
Pop open your terminal, plug in your phone, and type:
```bash
flutter run
```
That's it! 
*P.S. When you're ready for the heavy stuff, check out `NOTE_ME_FY_MASTERCLASS.md`.*
