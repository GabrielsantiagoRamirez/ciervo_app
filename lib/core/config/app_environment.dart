enum AppEnvironment { dev, staging, prod }

extension AppEnvironmentX on AppEnvironment {
  String get name => switch (this) {
    AppEnvironment.dev => 'dev',
    AppEnvironment.staging => 'staging',
    AppEnvironment.prod => 'prod',
  };

  /// URL base del API por ambiente.
  /// Override puntual: `--dart-define=API_BASE_URL=https://...`
  String get apiBaseUrl => switch (this) {
    AppEnvironment.prod => 'https://api.ciervo.club',
    AppEnvironment.staging => 'https://api.ciervo.club',
    // Dev usa el backend oficial; para local: API_BASE_URL=http://10.0.2.2:5xxx
    AppEnvironment.dev => 'https://api.ciervo.club',
  };

  bool get enablesVerboseLogs => this != AppEnvironment.prod;

  static AppEnvironment fromName(String value) {
    return switch (value.trim().toLowerCase()) {
      'prod' || 'production' => AppEnvironment.prod,
      'staging' || 'stage' => AppEnvironment.staging,
      _ => AppEnvironment.dev,
    };
  }
}
