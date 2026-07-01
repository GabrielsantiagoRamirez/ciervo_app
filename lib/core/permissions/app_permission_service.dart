import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../location/location_permission_status.dart';
import '../location/location_service.dart';

abstract interface class AppPermissionService {
  Future<bool> hasRequiredPermissions();

  Future<void> requestRequiredEntryPermissions();

  /// Solicita cámara solo cuando el usuario va a escanear QR o tomar foto.
  Future<bool> requestCameraIfNeeded();
}

class DeviceAppPermissionService implements AppPermissionService {
  const DeviceAppPermissionService(this._locationService);

  final LocationService _locationService;

  @override
  Future<bool> hasRequiredPermissions() async {
    final location = await _locationService.permissionStatus();
    final locationOk = location == AppLocationPermissionStatus.granted;
    final notificationOk = await _notificationGranted();
    return locationOk && notificationOk;
  }

  @override
  Future<void> requestRequiredEntryPermissions() async {
    await _ensureLocationServicesEnabled();
    await _requestLocation();
    await _requestNotifications();
    await _requestFirebaseMessagingPermission();
  }

  Future<void> _ensureLocationServicesEnabled() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (enabled) return;
    await _locationService.openLocationSettings();
  }

  Future<void> _requestLocation() async {
    final status = await _locationService.permissionStatus();
    if (status == AppLocationPermissionStatus.granted) return;
    if (status == AppLocationPermissionStatus.deniedForever) {
      await _locationService.openAppSettings();
      return;
    }
    await _locationService.requestPermission();
  }

  Future<void> _requestNotifications() async {
    final status = await Permission.notification.status;
    if (status.isGranted || status.isLimited) return;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }
    await Permission.notification.request();
  }

  Future<void> _requestFirebaseMessagingPermission() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (_) {}
  }

  Future<bool> _notificationGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited;
  }

  @override
  Future<bool> requestCameraIfNeeded() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    final result = await Permission.camera.request();
    return result.isGranted;
  }
}
