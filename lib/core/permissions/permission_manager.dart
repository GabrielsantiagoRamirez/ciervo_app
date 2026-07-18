import 'package:flutter/material.dart';

import '../di/service_locator.dart';
import '../notifications/ciervo_push_service.dart';
import 'app_permission_state.dart';
import 'app_permission_service.dart';
import 'permission_kind.dart';
import 'widgets/permission_explanation_modal.dart';

/// Punto central para solicitar permisos con explicación y reintentos.
class PermissionManager {
  PermissionManager(this._service);

  final AppPermissionService _service;

  static PermissionManager get instance =>
      PermissionManager(getIt<AppPermissionService>());

  Future<AppPermissionState> status(AppPermissionKind kind) =>
      _service.status(kind);

  Future<bool> openSettings() => _service.openSettings();

  Future<bool> ensure(
    BuildContext context,
    AppPermissionKind kind, {
    bool showExplanation = true,
  }) async {
    if (!context.mounted) return false;
    final current = await _service.status(kind);
    if (current.allowsUse) return true;
    if (!current.canRequest) return false;
    if (!context.mounted) return false;

    if (showExplanation) {
      final accepted = await showPermissionExplanationModal(
        context,
        kind: kind,
      );
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
    return _service.requestLocationIfNeeded();
  }

  Future<bool> _requestNotifications() async {
    final granted = await _service.requestNotificationsIfNeeded();
    if (granted && getIt.isRegistered<CiervoPushService>()) {
      final push = getIt<CiervoPushService>();
      await push.initialize();
      await push.syncTokenIfAuthenticated();
    }
    return granted;
  }

  Future<bool> _nfcAvailable() async {
    // Android no requiere permiso runtime para NFC en flujos de sesión backend.
    return true;
  }
}
