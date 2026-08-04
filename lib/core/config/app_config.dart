import 'package:flutter/foundation.dart';

import 'app_environment.dart';

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.refreshTokenPath,
    required this.connectTimeout,
    required this.receiveTimeout,
    this.moveOnboardingEnabled = false,
    this.moveTermsCoTextBase64 = '',
    this.moveTermsCoVersion = '',
    this.moveTermsCoContentHash = '',
    this.moveTermsClTextBase64 = '',
    this.moveTermsClVersion = '',
    this.moveTermsClContentHash = '',
  });

  /// Configuración central por ambiente.
  ///
  /// - `APP_ENV`: `dev` | `staging` | `prod` (en release sin define → `prod`)
  /// - `API_BASE_URL`: override opcional de la URL del API
  /// - `AUTH_REFRESH_PATH`: path de refresh (default `/api/auth/refresh-token`)
  factory AppConfig.fromEnvironment() {
    const environmentName = String.fromEnvironment('APP_ENV', defaultValue: '');
    const apiBaseUrlOverride = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );
    const refreshTokenPath = String.fromEnvironment(
      'AUTH_REFRESH_PATH',
      defaultValue: '/api/auth/refresh-token',
    );
    const moveOnboardingEnabledDefine = bool.fromEnvironment(
      'MOVE_ONBOARDING_ENABLED',
      defaultValue: false,
    );
    // En debug/dev el alta debe poder abrirse sin pelear con dart-defines.
    // En release solo con --dart-define=MOVE_ONBOARDING_ENABLED=true.
    final moveOnboardingEnabled =
        moveOnboardingEnabledDefine || !kReleaseMode;
    const moveTermsCoTextBase64 = String.fromEnvironment(
      'MOVE_TERMS_CO_TEXT_BASE64',
      defaultValue: '',
    );
    const moveTermsCoVersion = String.fromEnvironment(
      'MOVE_TERMS_CO_VERSION',
      defaultValue: '',
    );
    const moveTermsCoContentHash = String.fromEnvironment(
      'MOVE_TERMS_CO_CONTENT_HASH',
      defaultValue: '',
    );
    const moveTermsClTextBase64 = String.fromEnvironment(
      'MOVE_TERMS_CL_TEXT_BASE64',
      defaultValue: '',
    );
    const moveTermsClVersion = String.fromEnvironment(
      'MOVE_TERMS_CL_VERSION',
      defaultValue: '',
    );
    const moveTermsClContentHash = String.fromEnvironment(
      'MOVE_TERMS_CL_CONTENT_HASH',
      defaultValue: '',
    );

    final environment = environmentName.isNotEmpty
        ? AppEnvironmentX.fromName(environmentName)
        : (kReleaseMode ? AppEnvironment.prod : AppEnvironment.dev);

    final apiBaseUrl = apiBaseUrlOverride.isNotEmpty
        ? apiBaseUrlOverride
        : environment.apiBaseUrl;

    return AppConfig(
      environment: environment,
      apiBaseUrl: apiBaseUrl,
      refreshTokenPath: refreshTokenPath,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      moveOnboardingEnabled: moveOnboardingEnabled,
      moveTermsCoTextBase64: moveTermsCoTextBase64,
      moveTermsCoVersion: moveTermsCoVersion,
      moveTermsCoContentHash: moveTermsCoContentHash,
      moveTermsClTextBase64: moveTermsClTextBase64,
      moveTermsClVersion: moveTermsClVersion,
      moveTermsClContentHash: moveTermsClContentHash,
    );
  }

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String refreshTokenPath;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool moveOnboardingEnabled;
  final String moveTermsCoTextBase64;
  final String moveTermsCoVersion;
  final String moveTermsCoContentHash;
  final String moveTermsClTextBase64;
  final String moveTermsClVersion;
  final String moveTermsClContentHash;
}
