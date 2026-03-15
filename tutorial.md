# NoteMeFy: Beginner's Tutorial 🚀

Welcome! NoteMeFy is a fast, reactive idea-capture app built with **Flutter**, **Riverpod**, and **Hive**.

## 🧠 Core Concepts (Simplified)

1. **Flutter (The Paintbrush)**: Everything you see is a "Widget" (a Lego block).
2. **Hive (The Safe)**: A super-fast, local database that stores your captured thoughts on the device.
3. **Riverpod (The Nerves)**: State management. Think of it as a delivery system that automatically hands the newest data from Hive directly to the UI, so we never have to write "refresh" code.

## 🗺️ Project Map

*   `lib/main.dart`: The starting line. We set up our dark mode and launch the app here.
*   `lib/presentation/`: All the UI.
    *   `screens/capture_screen.dart`: The minimalist screen where you type.
    *   `screens/review_screen.dart`: The screen showing your list of ideas.
    *   `widgets/throw_action_area.dart`: The fun "Throw Note" swipe interaction.
*   `lib/data/repositories/note_repository.dart`: The middle-man that talks to the Hive database.
*   `lib/domain/models/`: Holds the `Note` blueprint.

## 🏃 How to Run

1. Open a terminal in the project folder.
2. Run this simple command:
   ```bash
   flutter run
   ```
3. To apply changes magically while it runs, type `r` in the terminal for a Hot Reload!
