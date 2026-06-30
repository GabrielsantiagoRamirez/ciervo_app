import 'package:permission_handler/permission_handler.dart';

import '../location/location_permission_status.dart';
import '../location/location_service.dart';

abstract interface class AppPermissionService {
  Future<void> requestRequiredEntryPermissions();

  /// Solicita cámara solo cuando el usuario va a escanear QR o tomar foto.
  Future<bool> requestCameraIfNeeded();
}

class DeviceAppPermissionService implements AppPermissionService {
  const DeviceAppPermissionService(this._locationService);

  final LocationService _locationService;

  @override
  Future<void> requestRequiredEntryPermissions() async {
    await _requestLocation();
    await _requestNotifications();
  }

  Future<void> _requestLocation() async {
    final status = await _locationService.permissionStatus();
    if (status == AppLocationPermissionStatus.unknown ||
        status == AppLocationPermissionStatus.denied) {
      await _locationService.requestPermission();
    }
  }

  Future<void> _requestNotifications() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
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
