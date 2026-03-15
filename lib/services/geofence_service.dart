import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geofence_service/geofence_service.dart';
import 'package:notemefy/domain/models/note.dart';
import 'package:notemefy/services/location_service.dart';
import 'package:notemefy/services/notification_service.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';

final geofenceServiceProvider = Provider<AppGeofenceService>((ref) {
  return AppGeofenceService();
});

// TUTORIAL: We use @pragma('vm:entry-point') here so the Dart compiler doesn't
// tree-shake (remove) this function. It needs to be accessible natively by iOS/Android
// when the app is completely killed, because background geofence callbacks run in a
// separate "Isolate" (a background thread).
@pragma('vm:entry-point')
Future<void> geofenceTaskCallback(
  Geofence geofence,
  GeofenceRadius geofenceRadius,
  GeofenceStatus geofenceStatus,
  Location location,
) async {
  // Required since this runs in a separate background isolate
  WidgetsFlutterBinding.ensureInitialized();

  // If the user enters the region
  if (geofenceStatus == GeofenceStatus.ENTER) {
    // TUTORIAL: We use SharedPreferences here instead of Hive or Riverpod because
    // background isolates don't share memory with the main app. Spinning up complex
    // database connections in the background can cause crashes or memory limits.
    // Key/value storage is perfect for passing small strings across thread boundaries.
    final prefs = await SharedPreferences.getInstance();
    final noteContent =
        prefs.getString('note_${geofence.id}') ??
        'You have a new captured idea here!';

    final notificationService = NotificationService();
    await notificationService.init();

    // Hash the ID to an int for the notification ID
    int notifId = geofence.id.hashCode;

    await notificationService.showNotification(
      id: notifId,
      title: 'Location Reminder 📍',
      body: noteContent,
    );
  }
}

class AppGeofenceService {
  final _geofenceService = GeofenceService.instance.setup(
    interval: 5000,
    accuracy: 100,
    loiteringDelayMs: 60000,
    statusChangeDelayMs: 10000,
    useActivityRecognition: false,
    allowMockLocations: false,
    printDevLog: true,
    geofenceRadiusSortType: GeofenceRadiusSortType.DESC,
  );

  AppGeofenceService();

  void initialize() {
    _geofenceService.addGeofenceStatusChangeListener((
      geofence,
      radius,
      status,
      location,
    ) async {
      // Foreground callback (also optionally fires same notification)
      await geofenceTaskCallback(geofence, radius, status, location);
    });
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
       // Ideally trigger a dialog here directing them to settings, 
       // but for now proceed to try and grab current location
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
        latitude: targetLat,
        longitude: targetLng,
        radius: [
          GeofenceRadius(id: 'radius_100m', length: 100),
        ],
      );

      try {
        _geofenceService.addGeofence(geofence);
        _geofenceService.start([geofence]).catchError((onError) {
          debugPrint('Geofence service start error: $onError');
        });
      } catch (e) {
        debugPrint('Geofence service start error: $e');
      }

    } catch (e) {
      debugPrint('Error registering geofence: $e');
    }
  }
}
