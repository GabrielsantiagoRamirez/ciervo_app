import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../storage/secure_storage.dart';
import 'app_location.dart';
import 'location_failure.dart';
import 'location_permission_status.dart';

abstract interface class LocationService {
  Future<AppLocationPermissionStatus> permissionStatus();

  Future<AppLocationPermissionStatus> requestPermission();

  Future<AppLocation> currentLocation();

  Future<AppLocation?> lastKnownLocation();

  Future<void> openAppSettings();

  Future<void> openLocationSettings();
}

class GeolocatorLocationService implements LocationService {
  GeolocatorLocationService(this._storage);

  static const _lastLatitudeKey = 'ciervo.location.lastLatitude';
  static const _lastLongitudeKey = 'ciervo.location.lastLongitude';
  static const _lastAccuracyKey = 'ciervo.location.lastAccuracy';

  final SecureStorage _storage;

  @override
  Future<AppLocationPermissionStatus> permissionStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return AppLocationPermissionStatus.serviceDisabled;
    }

    final permission = await Geolocator.checkPermission();
    return _mapPermission(permission);
  }

  @override
  Future<AppLocationPermissionStatus> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return AppLocationPermissionStatus.serviceDisabled;
    }

    final permission = await Geolocator.requestPermission();
    return _mapPermission(permission);
  }

  @override
  Future<AppLocation> currentLocation() async {
    final status = await permissionStatus();
    if (status != AppLocationPermissionStatus.granted) {
      throw LocationFailure(_failureType(status), _failureMessage(status));
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final location = AppLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
      await _saveLastKnownLocation(location);
      return location;
    } on LocationServiceDisabledException {
      throw const LocationFailure(
        LocationFailureType.serviceDisabled,
        'La ubicacion del dispositivo esta desactivada.',
      );
    } on PermissionDeniedException {
      throw const LocationFailure(
        LocationFailureType.denied,
        'No tenemos permiso para usar tu ubicacion.',
      );
    } on TimeoutException {
      throw const LocationFailure(
        LocationFailureType.timeout,
        'No pudimos obtener tu ubicacion a tiempo.',
      );
    } catch (error) {
      throw LocationFailure(
        LocationFailureType.unavailable,
        'No pudimos obtener tu ubicacion.',
      );
    }
  }

  @override
  Future<AppLocation?> lastKnownLocation() async {
    final latitude = double.tryParse(
      await _storage.read(_lastLatitudeKey) ?? '',
    );
    final longitude = double.tryParse(
      await _storage.read(_lastLongitudeKey) ?? '',
    );
    final accuracy = double.tryParse(
      await _storage.read(_lastAccuracyKey) ?? '',
    );

    if (latitude == null || longitude == null) {
      return null;
    }

    return AppLocation(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
    );
  }

  @override
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> _saveLastKnownLocation(AppLocation location) async {
    await _storage.write(_lastLatitudeKey, location.latitude.toStringAsFixed(4));
    await _storage.write(_lastLongitudeKey, location.longitude.toStringAsFixed(4));
    if (location.accuracy != null) {
      await _storage.write(_lastAccuracyKey, location.accuracy.toString());
    }
  }

  AppLocationPermissionStatus _mapPermission(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse =>
        AppLocationPermissionStatus.granted,
      LocationPermission.denied => AppLocationPermissionStatus.denied,
      LocationPermission.deniedForever =>
        AppLocationPermissionStatus.deniedForever,
      LocationPermission.unableToDetermine =>
        AppLocationPermissionStatus.unknown,
    };
  }

  LocationFailureType _failureType(AppLocationPermissionStatus status) {
    return switch (status) {
      AppLocationPermissionStatus.serviceDisabled =>
        LocationFailureType.serviceDisabled,
      AppLocationPermissionStatus.denied => LocationFailureType.denied,
      AppLocationPermissionStatus.deniedForever =>
        LocationFailureType.deniedForever,
      _ => LocationFailureType.unavailable,
    };
  }

  String _failureMessage(AppLocationPermissionStatus status) {
    return switch (status) {
      AppLocationPermissionStatus.serviceDisabled =>
        'Activa la ubicacion del dispositivo para ver lugares cercanos.',
      AppLocationPermissionStatus.denied =>
        'Puedes continuar sin ubicacion o permitirla para ver lugares cercanos.',
      AppLocationPermissionStatus.deniedForever =>
        'El permiso esta bloqueado. Puedes activarlo desde configuracion.',
      _ => 'No pudimos consultar el permiso de ubicacion.',
    };
  }
}
