import 'package:geolocator/geolocator.dart';

/// location_service.dart
///
/// HOW THIS WORKS:
/// 1. Ask the user for location permission (once).
/// 2. If granted, get the device's current GPS coordinates.
/// 3. Return the coordinates to the attendance screen which sends them to the backend.
///
/// The backend does the actual campus boundary check — this file just gets the coordinates.

class LocationService {
  /// Requests permission and returns current position.
  /// Returns null if permission is denied or GPS is off.
  /// Throws a [LocationException] with a reason so the UI knows what to show.
  static Future<Position> getCurrentPosition() async {
    // Check if location services (GPS) are enabled on the device
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        reason: LocationFailReason.serviceDisabled,
        message: 'GPS is disabled on your device. Please enable it to check in.',
      );
    }

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    // If denied, request it
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          reason: LocationFailReason.permissionDenied,
          message: 'Location permission was denied. Please allow it to check in.',
        );
      }
    }

    // If permanently denied, user must go to phone settings
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        reason: LocationFailReason.permissionPermanentlyDenied,
        message: 'Location permission is permanently denied. Please enable it in your phone settings.',
      );
    }

    // All good — get the current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Opens the phone's location settings (for permanently denied case)
  static Future<void> openSettings() async {
    await Geolocator.openLocationSettings();
  }
}

// ─── Custom exception types ───────────────────────────────────────────────────

enum LocationFailReason {
  serviceDisabled,          // GPS is off
  permissionDenied,         // user said "deny" to the popup
  permissionPermanentlyDenied, // user said "never ask again"
}

class LocationException implements Exception {
  final LocationFailReason reason;
  final String message;
  const LocationException({required this.reason, required this.message});
}