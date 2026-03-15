# 🚀 NoteMeFy: Day 1 Beginner's Pocket Guide

Welcome to **NoteMeFy**! Whether you are a brand new Flutter developer or just jumping into this specific project, this guide will give you the lay of the land without burying you in jargon. Let's get started!

## 🏗️ The Foundations

*   **Flutter & Dart**: We use Dart as the programming language and Flutter as the UI framework. Flutter is amazing because it lets us write code once and deploy it to iOS, Android, and Web natively!
*   **Riverpod**: This is our "state management" tool. Think of it as a central brain that holds all the app's current data (like notes, settings, or font size). When the brain updates, the UI instantly redraws to match!
*   **Local-First / Offline**: We don't rely on cloud databases that require an internet connection. Ideas strike anywhere, so everything is saved instantly using a hyper-fast local database called **Hive**.
*   **Geofencing**: The app asks "Where are you?" instead of just "What time is it?". The OS monitors your location natively and wakes up the app when you reach your home or office to resurface specific notes!

## 🧠 Core Concepts: Simplified!

*   **Providers (Riverpod)**: Imagine a Provider as a walkie-talkie channel. One part of the app broadcasts data on channel `fontSettingsProvider`, and the `SettingsScreen` simply tunes into that channel using `ref.watch(fontSettingsProvider)` to hear any changes.
*   **Isolates (Background Execution)**: Flutter normally runs all its UI on one main highway (thread). An "Isolate" is a parallel dirt-road that can do heavy lifting (like checking your GPS location) while the app is closed, without slowing down or touching the main UI highway.
*   **SharedPreferences**: A tiny filing cabinet where we store simple key-value settings (like "Theme = Dark" or "Tonight Hour = 8"). Perfect for quick reads!

## 🗺️ The Project Map

Here are the most important files you should know about, and what they do:

*   `lib/main.dart` ➡️ **The Starting Line.** This is where the app boots up, initializes the database, and loads the first screen.
*   `lib/domain/models/note.dart` ➡️ **The Blueprint.** This file explains what a "Note" is composed of (its text content, its color, its trigger logic).
*   `lib/presentation/screens/` ➡️ **The Paint.** All the UI files are in here! If you want to change what a button looks like, you go here (e.g., `capture_screen.dart` is the main note-taking page).
*   `lib/services/` ➡️ **The Mechanics.** The invisible engine code. `location_service.dart` talks to the GPS hardware, and `notification_service.dart` tells the OS to show a push notification.

## ▶️ How to Run the App (The Absolute Simplest Way)

1.  Connect an Android testing device via USB (or start an emulator in Android Studio).
2.  Open your terminal inside the `NoteMeFy` folder.
3.  Type `flutter run` and hit Enter!
4.  *(To update the app incredibly fast while writing code, press `r` in the terminal for a "Hot Reload"!)*
