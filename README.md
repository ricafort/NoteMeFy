# NoteMeFy 📝📍

NoteMeFy is a smart, offline-first notes capture application built with Flutter. It combines rapid idea capture with intelligent, location-based triggers (geofencing) and an aesthetic, dynamic UI.

## Features ✨

*   **Lightning-Fast Capture**: Drop your thoughts into the app instantly.
*   **Location Triggers (Geofencing)**: Set your "Home" or "Work" locations. NoteMeFy will ping you with your notes when you enter those specific areas!
*   **Offline-First**: Built with local, secure data storage using Hive.
*   **Dynamic Typography**: Customize your viewing experience. 
*   **Premium Aesthetics**: Fluid animations, haptic feedback, and a clean interface.

## Tech Stack 🛠

*   **Framework**: [Flutter](https://flutter.dev/)
*   **State Management**: [Riverpod](https://riverpod.dev/)
*   **Local Storage**: [Hive](https://docs.hivedb.dev/)
*   **Location & Geofencing**: `geolocator`, `geofence_service`
*   **Background Tasks**: Isolates for background geofence callbacks.

## Getting Started 🚀

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/ricafort/NoteMeFy.git
    cd NoteMeFy
    ```
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the app**:
    ```bash
    flutter run
    ```

## Development & Architecture 🏗

NoteMeFy uses a Feature-First architecture with Riverpod for reactive state management. 

*   `lib/domain/`: Core data models (e.g., `Note`).
*   `lib/data/`: Repositories and local database (Hive) implementation.
*   `lib/services/`: App utilities (Location, Notifications, Haptics).
*   `lib/presentation/`: UI screens and customized widgets.

### Setting up Triggers

1. Navigate to **Settings**.
2. Tap **Set Home** or **Set Work** to save your current physical location.
3. When creating a note, tap the compass icon in the Smart Trigger Bar to attach a location rule.

---
*Built with Flutter.*
