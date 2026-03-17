import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:notemefy/domain/models/note.dart';
import 'package:notemefy/services/location_service.dart';
import 'package:notemefy/services/notification_service.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';

final geofenceServiceProvider = Provider<AppGeofenceService>((ref) {
  return AppGeofenceService();
});

// TUTORIAL: Background Isolates 
// When the app is terminated and the phone enters a geofence, the OS wakes the app up invisibly.
// Dart uses an "Isolate" (a separate memory space/thread) to run code without touching the UI.
// `@pragma('vm:entry-point')` prevents the Flutter compiler from deleting this function during tree-shaking
// so the OS can always find it when it needs to be triggered!
@pragma('vm:entry-point')
Future<void> geofenceTriggered(GeofenceCallbackParams params) async {
  // TUTORIAL: We must ensure Flutter is ready to run Dart code from cold storage before doing anything
  WidgetsFlutterBinding.ensureInitialized();

  if (params.event == GeofenceEvent.enter) {
    final prefs = await SharedPreferences.getInstance();
    // TUTORIAL: The background thread isn't allowed to draw Permission Dialogs to the screen.
    // If we call a standard initialization that requests location/notification permissions here,
    // the OS throws a fatal exception and immediately kills our background thread.
    // Hence, `isBackground: true` skips the UI permission request!
    final notificationService = NotificationService();
    await notificationService.init(isBackground: true);

    for (final geofence in params.geofences) {
      final noteContent =
          prefs.getString('note_${geofence.id}') ??
          'You have a new captured idea here!';

      debugPrint('NoteMeFy: Geofence triggered for ID: ${geofence.id}');
      int notifId = geofence.id.hashCode;

      await notificationService.showNotification(
        id: notifId,
        title: 'Location Reminder 📍',
        body: noteContent,
        payload: geofence.id,
      );
      debugPrint('NoteMeFy: Fired background notification with payload: ${geofence.id}');
    }
  }
}

class AppGeofenceService {
  AppGeofenceService();

  Future<void> initialize() async {
    // Initialization is called globally in main.dart via NativeGeofenceManager.instance.initialize();
  }

  Future<void> registerLocationTrigger(Note note) async {
    if (note.triggerType != TriggerType.home && note.triggerType != TriggerType.work) {
      return;
    }

    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location service disabled');
      return;
    }

    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        debugPrint('Location permission denied');
        return;
      }
    }
    
    // Background location usually needs 'always'
    if (permission == geo.LocationPermission.whileInUse) {
       debugPrint('Warning: Location permission is whileInUse, background geofencing might be unreliable.');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      
      double? targetLat;
      double? targetLng;

      if (note.triggerType == TriggerType.home) {
        targetLat = prefs.getDouble(LocationService.homeLatKey);
        targetLng = prefs.getDouble(LocationService.homeLngKey);
      } else if (note.triggerType == TriggerType.work) {
        targetLat = prefs.getDouble(LocationService.workLatKey);
        targetLng = prefs.getDouble(LocationService.workLngKey);
      }

      if (targetLat == null || targetLng == null) {
        debugPrint('Error: Saved location for ${note.triggerType.name} not found.');
        return;
      }

      // Save the note content so the background isolate can read it
      await prefs.setString('note_${note.id}', note.content);

      final geofence = Geofence(
        id: note.id,
        location: Location(latitude: targetLat, longitude: targetLng),
        radiusMeters: 100,
        triggers: {GeofenceEvent.enter},
        iosSettings: IosGeofenceSettings(
          initialTrigger: false, 
        ),
        androidSettings: AndroidGeofenceSettings(
          initialTriggers: {GeofenceEvent.enter},
          expiration: const Duration(days: 365), 
          notificationResponsiveness: const Duration(minutes: 0),
        ),
      );

      try {
        await NativeGeofenceManager.instance.createGeofence(geofence, geofenceTriggered);
        debugPrint('Registered native geofence for note ${note.id}');
      } catch (e) {
        debugPrint('Geofence create/register error: $e');
      }

    } catch (e) {
      debugPrint('Error preparing geofence: $e');
    }
  }
}
