import 'package:geolocator/geolocator.dart';

/// Service for handling location permissions and fetching user location
class LocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission from the user
  /// Returns the new permission status after request
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get the current position
  /// Throws an exception if permission is denied or location services are disabled
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    Duration? timeout,
  }) async {
    // Check if location services are enabled
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw AppLocationServiceDisabledException();
    }

    // Check permission
    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw AppLocationPermissionDeniedException();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw AppLocationPermissionDeniedForeverException();
    }

    // Get position - use the correct API for geolocator 11.x
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: accuracy,
      timeLimit: timeout ?? const Duration(seconds: 10),
    );
  }

  /// Get the last known position (faster but may be stale)
  Future<Position?> getLastKnownPosition() async {
    return await Geolocator.getLastKnownPosition();
  }

  /// Open location settings (for when permission is denied forever)
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (for when permission is denied forever on iOS)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Check if we have sufficient permission to get location
  Future<bool> hasPermission() async {
    final permission = await checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Geocode a zipcode to lat/lng coordinates
  /// In production, this would call a geocoding API
  Future<Map<String, double>?> geocodeZipcode(String zipcode) async {
    // Mock implementation for development
    // In production, use a geocoding service like Google Geocoding API
    await Future.delayed(const Duration(milliseconds: 300));

    // Mock coordinates for common test zipcodes
    final mockCoordinates = {
      '10001': {'latitude': 40.7484, 'longitude': -73.9967}, // NYC
      '90210': {'latitude': 34.0901, 'longitude': -118.4065}, // Beverly Hills
      '60601': {'latitude': 41.8819, 'longitude': -87.6278}, // Chicago
      '98101': {'latitude': 47.6062, 'longitude': -122.3321}, // Seattle
      '33101': {'latitude': 25.7617, 'longitude': -80.1918}, // Miami
    };

    // For development, return mock coordinates or generate random ones
    if (mockCoordinates.containsKey(zipcode)) {
      return mockCoordinates[zipcode];
    }

    // For any valid 5-digit zipcode, generate mock coordinates
    if (zipcode.length == 5 && int.tryParse(zipcode) != null) {
      // Generate pseudo-random but consistent coordinates based on zipcode
      final seed = int.parse(zipcode);
      final lat = 25.0 + (seed % 25); // Between 25 and 50 (US latitude range)
      final lng = -125.0 + (seed % 55); // Between -125 and -70 (US longitude range)
      return {'latitude': lat.toDouble(), 'longitude': lng.toDouble()};
    }

    return null;
  }
}

/// Exception thrown when location services are disabled
class AppLocationServiceDisabledException implements Exception {
  final String message = 'Location services are disabled';
  @override
  String toString() => message;
}

/// Exception thrown when location permission is denied
class AppLocationPermissionDeniedException implements Exception {
  final String message = 'Location permission denied';
  @override
  String toString() => message;
}

/// Exception thrown when location permission is denied forever
class AppLocationPermissionDeniedForeverException implements Exception {
  final String message = 'Location permission denied forever';
  @override
  String toString() => message;
}
