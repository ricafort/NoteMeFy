# NoteMeFy: Beginner's Pocket Guide

Hey! Welcome to the day-1 map of **NoteMeFy**! We're building a smart-journaling tool that isn't just a list—it actively wakes up when you arrive at specific places (like home or work). 

## 🏗️ Language Foundations: Dart & Flutter
- **Flutter** is the engine. It draws all the buttons and text to the screen really fast. 
- **Dart** is the programming language we write. It's safe, structured, and easy to read.
- We use a pattern called **Riverpod** to wire up the app. Imagine Riverpod as a big speaker system—when data changes (like deleting a note), Riverpod announces it to the entire UI so the screen updates instantly.

## 🧠 Key Concepts
- **Isolates (Background Threads):** The app runs even when the phone is locked. It uses "Isolates", which are like completely separate ghost apps running in the dark, checking your GPS.
- **Geofencing:** We draw an invisible digital circle around your home. When your phone crosses the line, the OS rings an alarm.
- **Single Source of Truth:** Your local database (`Hive`) determines what should exist. If a geofence runs rogue in the background, but the database says the note is deleted, our cleanup system hunts that rogue geofence down and kills it!

## 🗺️ Project Map
- `lib/main.dart`: The ignition switch. Bootstraps the app and sets up the Native Geofences.
- `lib/domain/models/`: Where we define *what* a `Note` is.
- `lib/data/repositories/`: Where we store and retrieve the notes locally using `Hive` (the database).
- `lib/presentation/`: The UI screens that the user taps and plays with.
- `lib/services/`: The heavy lifting! Background services, notification triggers, and geofencing systems live here.

## 🚀 How to Run
It's just one line! Open your terminal, plug in your phone, and type:
```bash
flutter run
```
