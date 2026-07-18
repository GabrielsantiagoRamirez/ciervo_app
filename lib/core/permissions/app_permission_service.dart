import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:permission_handler/permission_handler.dart';

import '../location/location_permission_status.dart';
import '../notifications/notification_presenter.dart';
import '../location/location_service.dart';
import 'app_permission_state.dart';
import 'permission_kind.dart';

abstract interface class AppPermissionService {
  Future<bool> hasRequiredPermissions();

  Future<AppPermissionState> status(AppPermissionKind kind);

  Future<bool> openSettings();

  @Deprecated('Los permisos deben solicitarse dentro del flujo que los usa.')
  Future<void> requestRequiredEntryPermissions();

  Future<bool> requestLocationIfNeeded();

  Future<bool> requestNotificationsIfNeeded();

  /// Solicita cámara solo cuando el usuario va a escanear QR o tomar foto.
  Future<bool> requestCameraIfNeeded();

  /// Solicita acceso a fotos/galería para escanear QR desde imagen.
  Future<bool> requestPhotosIfNeeded();

  /// Solicita acceso a contactos para encontrar usuarios CIERVO.
  Future<bool> requestContactsIfNeeded();
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
  Future<AppPermissionState> status(AppPermissionKind kind) async {
    if (kind == AppPermissionKind.location) {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return AppPermissionState.serviceDisabled;
      }
      final value = await _locationService.permissionStatus();
      return switch (value) {
        AppLocationPermissionStatus.granted => AppPermissionState.granted,
        AppLocationPermissionStatus.denied => AppPermissionState.denied,
        AppLocationPermissionStatus.deniedForever =>
          AppPermissionState.permanentlyDenied,
        AppLocationPermissionStatus.serviceDisabled =>
          AppPermissionState.serviceDisabled,
        AppLocationPermissionStatus.unknown => AppPermissionState.unknown,
      };
    }
    if (kind == AppPermissionKind.nfc) {
      try {
        return await NfcManager.instance.isAvailable()
            ? AppPermissionState.granted
            : AppPermissionState.unavailable;
      } catch (_) {
        return AppPermissionState.unavailable;
      }
    }
    if (kind == AppPermissionKind.notifications) {
      try {
        final settings = await FirebaseMessaging.instance
            .getNotificationSettings();
        return switch (settings.authorizationStatus) {
          AuthorizationStatus.authorized => AppPermissionState.granted,
          AuthorizationStatus.provisional => AppPermissionState.limited,
          AuthorizationStatus.notDetermined => AppPermissionState.notDetermined,
          AuthorizationStatus.denied => _mapPermissionStatus(
            await Permission.notification.status,
          ),
        };
      } catch (_) {
        return _mapPermissionStatus(await Permission.notification.status);
      }
    }
    if (kind == AppPermissionKind.photos) {
      final photos = _mapPermissionStatus(await Permission.photos.status);
      if (photos.allowsUse || photos.needsSettings) return photos;
      return _mapPermissionStatus(await Permission.storage.status);
    }
    final value = await switch (kind) {
      AppPermissionKind.camera => Permission.camera.status,
      AppPermissionKind.contacts => Permission.contacts.status,
      AppPermissionKind.photos ||
      AppPermissionKind.notifications ||
      AppPermissionKind.location ||
      AppPermissionKind.nfc => Future.value(PermissionStatus.denied),
    };
    return _mapPermissionStatus(value);
  }

  @override
  Future<bool> openSettings() => openAppSettings();

  @override
  Future<void> requestRequiredEntryPermissions() async {
    // Se conserva temporalmente por compatibilidad. No debe abrir prompts
    // globales; cada flujo solicita únicamente el permiso que necesita.
  }

  Future<bool> _ensureLocationServicesEnabled() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (enabled) return true;
    return false;
  }

  @override
  Future<bool> requestLocationIfNeeded() async {
    if (!await _ensureLocationServicesEnabled()) return false;
    final status = await _locationService.permissionStatus();
    if (status == AppLocationPermissionStatus.granted) return true;
    if (status == AppLocationPermissionStatus.deniedForever) return false;
    return await _locationService.requestPermission() ==
        AppLocationPermissionStatus.granted;
  }

  @override
  Future<bool> requestNotificationsIfNeeded() async {
    final status = await Permission.notification.status;
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied || status.isRestricted) return false;
    final localPermission =
        await NotificationPresenter.requestDisplayPermission();
    if (!localPermission) return false;
    return _requestFirebaseMessagingPermission();
  }

  Future<bool> _requestFirebaseMessagingPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _notificationGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited;
  }

  @override
  Future<bool> requestCameraIfNeeded() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied || status.isRestricted) return false;
    final result = await Permission.camera.request();
    return result.isGranted;
  }

  @override
  Future<bool> requestContactsIfNeeded() async {
    final status = await Permission.contacts.status;
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied || status.isRestricted) return false;
    final result = await Permission.contacts.request();
    return result.isGranted || result.isLimited;
  }

  @override
  Future<bool> requestPhotosIfNeeded() async {
    final photos = await Permission.photos.status;
    if (photos.isGranted || photos.isLimited) return true;

    final storage = await Permission.storage.status;
    if (storage.isGranted || storage.isLimited) return true;

    if (photos.isPermanentlyDenied ||
        photos.isRestricted ||
        storage.isPermanentlyDenied ||
        storage.isRestricted) {
      return false;
    }

    final photosResult = await Permission.photos.request();
    if (photosResult.isGranted || photosResult.isLimited) return true;

    final storageResult = await Permission.storage.request();
    return storageResult.isGranted || storageResult.isLimited;
  }

  AppPermissionState _mapPermissionStatus(PermissionStatus status) {
    if (status.isGranted) return AppPermissionState.granted;
    if (status.isLimited) return AppPermissionState.limited;
    if (status.isPermanentlyDenied) {
      return AppPermissionState.permanentlyDenied;
    }
    if (status.isRestricted) return AppPermissionState.restricted;
    if (status.isDenied) return AppPermissionState.denied;
    return AppPermissionState.unknown;
  }
}
