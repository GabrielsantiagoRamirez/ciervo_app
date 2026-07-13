import 'package:flutter/foundation.dart';

import 'app_environment.dart';

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.refreshTokenPath,
    required this.connectTimeout,
    required this.receiveTimeout,
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
    );
  }

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String refreshTokenPath;
  final Duration connectTimeout;
  final Duration receiveTimeout;
}
