import 'dart:async';

import 'package:geolocator/geolocator.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

/// Describes why the location could not be obtained.
enum LocationIssue {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unavailable,
}

// ─── Exception ────────────────────────────────────────────────────────────────

/// Thrown by [LocationService] when the device position cannot be resolved.
class LocationException implements Exception {
  const LocationException(this.issue, this.message);

  final LocationIssue issue;
  final String message;

  @override
  String toString() => 'LocationException($issue): $message';
}

// ─── Result ───────────────────────────────────────────────────────────────────

/// Immutable wrapper around a device position.
class LocationResult {
  const LocationResult({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  String toString() => 'LocationResult($latitude, $longitude)';
}

// ─── Service ──────────────────────────────────────────────────────────────────

/// Service responsible **only** for obtaining the device's current position.
///
/// SRP: no UI, no map logic — just location access via [Geolocator].
class LocationService {
  /// Check current permission status without requesting anything.
  Future<LocationPermission> checkPermission() async {
    return Geolocator.checkPermission();
  }

  /// Request permission from the user.
  Future<LocationPermission> requestPermission() async {
    return Geolocator.requestPermission();
  }

  /// Whether the location service is enabled on the device.
  Future<bool> isServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// Open the device's location settings screen.
  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }

  /// Open the app settings (for permanently denied permissions).
  Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }

  /// Obtains the current device position.
  ///
  /// Throws [LocationException] if:
  /// - Location services are disabled.
  /// - Permission is denied or permanently denied.
  /// - The request times out and no cached position is available.
  Future<LocationResult> getCurrentPosition({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    // 1. Check services
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        LocationIssue.servicesDisabled,
        'Activa la ubicación del dispositivo para centrar el mapa en tu posición real.',
      );
    }

    // 2. Check / request permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(
        LocationIssue.permissionDenied,
        'No concediste permiso de ubicación. Puedes mover el mapa manualmente.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        LocationIssue.permissionDeniedForever,
        'El permiso de ubicación está bloqueado. Ábrelo en los ajustes del sistema.',
      );
    }

    // 3. Fetch position (with fallback to last known)
    final lastKnown = await Geolocator.getLastKnownPosition();

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      ).timeout(timeout);

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on TimeoutException {
      if (lastKnown != null) {
        return LocationResult(
          latitude: lastKnown.latitude,
          longitude: lastKnown.longitude,
        );
      }
      throw const LocationException(
        LocationIssue.timeout,
        'La ubicación tardó demasiado. Se muestra una ubicación por defecto.',
      );
    }
  }
}
