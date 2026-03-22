# Beginner's Pocket Guide to NoteMeFy

Hey! Welcome to the day-1 map of **NoteMeFy**! We're building a smart-journaling tool that isn't just a list—it actively wakes up when you arrive at specific places (like home or work).

## 🏗️ Language Foundations: Dart & Flutter
- **Flutter** is our UI engine. It draws all the buttons, text fields, and animations to the screen extremely fast.
- **Dart** is our programming language. It feels very similar to Java or JavaScript—it's object-oriented, structured, and easy to read.
- We use a pattern called **Riverpod** to wire up the app. Think of Riverpod as a central PA system 📢. When data changes (like saving a note), Riverpod announces it to the entire UI so the screen updates instantly.

## 🧠 Key Concepts
- **Isolates (Ghost Apps):** The app runs even when your phone is locked. It uses "Isolates" (background threads) which act like separate invisible mini-apps running in the dark, checking your GPS.
- **Geofencing:** We draw an invisible digital circle 🌍 around your home coordinates. When your phone crosses the line, the OS rings an alarm.
- **Single Source of Truth:** Your local database (`Hive`) dictates reality. If a geofence runs rogue in the background, but the database says the note is deleted, our cleanup system hunts that rogue geofence down when you launch the app and kills it!
- **AMOLED Dark Mode:** We use pure black (`#000000`). It turns off individual screen pixels, saving tons of battery 🔋!

## 🗺️ Project Map
- `lib/main.dart`: The ignition switch. Bootstraps the app, sets the AMOLED theme, and syncs the Geofences.
- `lib/domain/models/`: Where we define the blueprint of *what* a `Note` is.
- `lib/data/repositories/`: Where we store and retrieve notes locally using `Hive` (our lightning-fast database).
- `lib/presentation/`: The UI screens that the user taps and plays with.
- `lib/services/`: The brains! Background services, notification triggers, and geofencing systems live here.

## 🚀 How to Run
It's just one line! Open your terminal, plug in your phone or simulator, and type:
```bash
flutter run
```
