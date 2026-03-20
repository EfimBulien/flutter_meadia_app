import 'package:location/location.dart';

class LocationService {
  static final Location _location = Location();

  static Future<bool> requestLocationPermission() async {
    final status = await _location.requestPermission();
    return status == PermissionStatus.granted;
  }

  static Future<LocationData?> getLocation() async {
    try {
      final serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        final result = await _location.requestService();
        if (!result) {
          return null;
        }
      }

      final permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        final result = await _location.requestPermission();
        if (result != PermissionStatus.granted) {
          return null;
        }
      }

      return await _location.getLocation();
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  static Future<String> getLocationAddress(double latitude, double longitude) async {
    // Simple implementation using coordinates
    // In production, use a reverse geocoding service
    return '$latitude, $longitude';
  }
}
