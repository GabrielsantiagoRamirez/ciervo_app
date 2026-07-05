import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../di/service_locator.dart';
import 'app_permission_service.dart';
import 'permission_kind.dart';
import 'widgets/permission_explanation_modal.dart';

/// Punto central para solicitar permisos con explicación y reintentos.
class PermissionManager {
  PermissionManager(this._service);

  final AppPermissionService _service;

  static PermissionManager get instance =>
      PermissionManager(getIt<AppPermissionService>());

  Future<bool> ensure(
    BuildContext context,
    AppPermissionKind kind, {
    bool showExplanation = true,
  }) async {
    if (!context.mounted) return false;

    if (showExplanation) {
      final accepted = await showPermissionExplanationModal(context, kind: kind);
      if (!accepted || !context.mounted) return false;
    }

    return switch (kind) {
      AppPermissionKind.camera => _service.requestCameraIfNeeded(),
      AppPermissionKind.photos => _service.requestPhotosIfNeeded(),
      AppPermissionKind.contacts => _service.requestContactsIfNeeded(),
      AppPermissionKind.location => _requestLocation(),
      AppPermissionKind.notifications => _requestNotifications(),
      AppPermissionKind.nfc => _nfcAvailable(),
    };
  }

  Future<bool> _requestLocation() async {
    await _service.requestRequiredEntryPermissions();
    return true;
  }

  Future<bool> _requestNotifications() async {
    final status = await Permission.notification.status;
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    final result = await Permission.notification.request();
    return result.isGranted || result.isLimited;
  }

  Future<bool> _nfcAvailable() async {
    // Android no requiere permiso runtime para NFC en flujos de sesión backend.
    return true;
  }
}
