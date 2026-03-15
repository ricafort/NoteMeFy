import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class LocationService {
  static const String homeLatKey = 'home_lat';
  static const String homeLngKey = 'home_lng';
  static const String workLatKey = 'work_lat';
  static const String workLngKey = 'work_lng';

  Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<bool> saveHomeLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final pos = await getCurrentLocation();
    if (pos != null) {
      await prefs.setDouble(homeLatKey, pos.latitude);
      await prefs.setDouble(homeLngKey, pos.longitude);
      return true;
    }
    return false;
  }

  Future<bool> saveWorkLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final pos = await getCurrentLocation();
    if (pos != null) {
      await prefs.setDouble(workLatKey, pos.latitude);
      await prefs.setDouble(workLngKey, pos.longitude);
      return true;
    }
    return false;
  }
}
