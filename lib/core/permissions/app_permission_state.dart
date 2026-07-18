enum AppPermissionState {
  unknown,
  notDetermined,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  granted,
  serviceDisabled,
  unavailable,
}

extension AppPermissionStateX on AppPermissionState {
  bool get allowsUse =>
      this == AppPermissionState.granted || this == AppPermissionState.limited;

  bool get canRequest =>
      this == AppPermissionState.notDetermined ||
      this == AppPermissionState.denied;

  bool get needsSettings =>
      this == AppPermissionState.permanentlyDenied ||
      this == AppPermissionState.serviceDisabled;
}
