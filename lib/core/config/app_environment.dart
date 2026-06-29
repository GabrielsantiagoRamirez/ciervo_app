enum AppEnvironment { dev, staging, prod }

extension AppEnvironmentX on AppEnvironment {
  String get name => switch (this) {
        AppEnvironment.dev => 'dev',
        AppEnvironment.staging => 'staging',
        AppEnvironment.prod => 'prod',
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
