import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/location_service.dart';

// Location service provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// User location state
class UserLocation {
  final double? latitude;
  final double? longitude;
  final String? zipcode;
  final String source; // 'gps', 'zipcode', 'none'
  final DateTime? updatedAt;

  const UserLocation({
    this.latitude,
    this.longitude,
    this.zipcode,
    this.source = 'none',
    this.updatedAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

  UserLocation copyWith({
    double? latitude,
    double? longitude,
    String? zipcode,
    String? source,
    DateTime? updatedAt,
  }) {
    return UserLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      zipcode: zipcode ?? this.zipcode,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'zipcode': zipcode,
        'source': source,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      zipcode: json['zipcode'] as String?,
      source: json['source'] as String? ?? 'none',
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}

// Location state with loading/error
class LocationState {
  final UserLocation location;
  final bool isLoading;
  final bool isRequestingPermission;
  final LocationPermission? permissionStatus;
  final String? error;
  final bool hasPromptedForLocation;

  const LocationState({
    this.location = const UserLocation(),
    this.isLoading = false,
    this.isRequestingPermission = false,
    this.permissionStatus,
    this.error,
    this.hasPromptedForLocation = false,
  });

  LocationState copyWith({
    UserLocation? location,
    bool? isLoading,
    bool? isRequestingPermission,
    LocationPermission? permissionStatus,
    String? error,
    bool? hasPromptedForLocation,
  }) {
    return LocationState(
      location: location ?? this.location,
      isLoading: isLoading ?? this.isLoading,
      isRequestingPermission: isRequestingPermission ?? this.isRequestingPermission,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      error: error,
      hasPromptedForLocation: hasPromptedForLocation ?? this.hasPromptedForLocation,
    );
  }
}

// Location state notifier
class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  static const String _locationLatKey = 'user_location_lat';
  static const String _locationLngKey = 'user_location_lng';
  static const String _locationZipcodeKey = 'user_location_zipcode';
  static const String _locationSourceKey = 'user_location_source';
  static const String _locationPromptedKey = 'user_location_prompted';

  LocationNotifier(this._locationService) : super(const LocationState()) {
    _loadSavedLocation();
  }

  /// Load saved location from preferences
  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_locationLatKey);
      final lng = prefs.getDouble(_locationLngKey);
      final zipcode = prefs.getString(_locationZipcodeKey);
      final source = prefs.getString(_locationSourceKey) ?? 'none';
      final prompted = prefs.getBool(_locationPromptedKey) ?? false;

      if (lat != null && lng != null) {
        state = state.copyWith(
          location: UserLocation(
            latitude: lat,
            longitude: lng,
            zipcode: zipcode,
            source: source,
            updatedAt: DateTime.now(),
          ),
          hasPromptedForLocation: prompted,
        );
      } else {
        state = state.copyWith(hasPromptedForLocation: prompted);
      }

      // Check current permission status
      final permission = await _locationService.checkPermission();
      state = state.copyWith(permissionStatus: permission);
    } catch (e) {
      // Ignore errors loading saved location
    }
  }

  /// Save location to preferences
  Future<void> _saveLocation(UserLocation location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (location.latitude != null) {
        await prefs.setDouble(_locationLatKey, location.latitude!);
      }
      if (location.longitude != null) {
        await prefs.setDouble(_locationLngKey, location.longitude!);
      }
      if (location.zipcode != null) {
        await prefs.setString(_locationZipcodeKey, location.zipcode!);
      }
      await prefs.setString(_locationSourceKey, location.source);
    } catch (e) {
      // Ignore errors saving location
    }
  }

  /// Mark that we've prompted the user for location
  Future<void> markAsPrompted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_locationPromptedKey, true);
      state = state.copyWith(hasPromptedForLocation: true);
    } catch (e) {
      state = state.copyWith(hasPromptedForLocation: true);
    }
  }

  /// Request location permission and get current position
  /// Returns true if location was successfully obtained
  Future<bool> requestLocationPermission() async {
    state = state.copyWith(isRequestingPermission: true, error: null);

    try {
      // Request permission (this triggers the native OS dialog)
      final permission = await _locationService.requestPermission();
      state = state.copyWith(permissionStatus: permission);

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isRequestingPermission: false,
          error: permission == LocationPermission.deniedForever
              ? 'Location permission permanently denied. Please enable in settings.'
              : 'Location permission denied',
        );
        return false;
      }

      // Permission granted, get current position
      return await detectLocation();
    } catch (e) {
      state = state.copyWith(
        isRequestingPermission: false,
        error: 'Failed to request location permission',
      );
      return false;
    }
  }

  /// Detect current location using GPS
  Future<bool> detectLocation() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final position = await _locationService.getCurrentPosition();

      final location = UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        source: 'gps',
        updatedAt: DateTime.now(),
      );

      await _saveLocation(location);

      state = state.copyWith(
        location: location,
        isLoading: false,
        isRequestingPermission: false,
      );

      // TODO: Call API to save location to user profile
      // await _saveLocationToServer(location);

      return true;
    } on AppLocationServiceDisabledException {
      state = state.copyWith(
        isLoading: false,
        isRequestingPermission: false,
        error: 'Please enable location services',
      );
      return false;
    } on AppLocationPermissionDeniedException {
      state = state.copyWith(
        isLoading: false,
        isRequestingPermission: false,
        error: 'Location permission denied',
      );
      return false;
    } on AppLocationPermissionDeniedForeverException {
      state = state.copyWith(
        isLoading: false,
        isRequestingPermission: false,
        error: 'Location permission permanently denied',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRequestingPermission: false,
        error: 'Failed to get location',
      );
      return false;
    }
  }

  /// Set location from zipcode
  Future<bool> setLocationFromZipcode(String zipcode) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final coordinates = await _locationService.geocodeZipcode(zipcode);

      if (coordinates == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid zipcode',
        );
        return false;
      }

      final location = UserLocation(
        latitude: coordinates['latitude'],
        longitude: coordinates['longitude'],
        zipcode: zipcode,
        source: 'zipcode',
        updatedAt: DateTime.now(),
      );

      await _saveLocation(location);

      state = state.copyWith(
        location: location,
        isLoading: false,
      );

      // TODO: Call API to save location to user profile
      // await _saveLocationToServer(location);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to geocode zipcode',
      );
      return false;
    }
  }

  /// Open location settings
  Future<void> openSettings() async {
    await _locationService.openAppSettings();
  }

  /// Clear location data
  Future<void> clearLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_locationLatKey);
      await prefs.remove(_locationLngKey);
      await prefs.remove(_locationZipcodeKey);
      await prefs.remove(_locationSourceKey);
    } catch (e) {
      // Ignore errors
    }

    state = state.copyWith(
      location: const UserLocation(),
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Location state provider
final locationStateProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return LocationNotifier(locationService);
});

// Convenience providers
final userLocationProvider = Provider<UserLocation>((ref) {
  return ref.watch(locationStateProvider).location;
});

final hasLocationProvider = Provider<bool>((ref) {
  return ref.watch(locationStateProvider).location.hasLocation;
});

final shouldPromptLocationProvider = Provider<bool>((ref) {
  final state = ref.watch(locationStateProvider);
  return !state.location.hasLocation && !state.hasPromptedForLocation;
});
