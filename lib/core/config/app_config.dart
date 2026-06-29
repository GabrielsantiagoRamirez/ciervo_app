import 'app_environment.dart';

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.refreshTokenPath,
    required this.connectTimeout,
    required this.receiveTimeout,
  });

  factory AppConfig.fromEnvironment() {
    const environmentName = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'dev',
    );
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue:
          'https://ciervo-backend-613568140358.southamerica-east1.run.app',
    );
    const refreshTokenPath = String.fromEnvironment(
      'AUTH_REFRESH_PATH',
      defaultValue: '/api/auth/refresh-token',
    );

    return AppConfig(
      environment: AppEnvironmentX.fromName(environmentName),
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
