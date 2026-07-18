import 'package:ciervo_clud/core/permissions/app_permission_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('solo estados concedidos permiten usar la capacidad', () {
    expect(AppPermissionState.granted.allowsUse, isTrue);
    expect(AppPermissionState.limited.allowsUse, isTrue);
    expect(AppPermissionState.denied.allowsUse, isFalse);
    expect(AppPermissionState.restricted.allowsUse, isFalse);
  });

  test('distingue solicitud explícita de apertura de ajustes', () {
    expect(AppPermissionState.notDetermined.canRequest, isTrue);
    expect(AppPermissionState.denied.canRequest, isTrue);
    expect(AppPermissionState.permanentlyDenied.canRequest, isFalse);
    expect(AppPermissionState.permanentlyDenied.needsSettings, isTrue);
    expect(AppPermissionState.serviceDisabled.needsSettings, isTrue);
  });
}
