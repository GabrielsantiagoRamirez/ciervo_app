class MoveTermsConfiguration {
  const MoveTermsConfiguration({
    required this.countryCode,
    required this.text,
    required this.version,
    required this.contentHash,
  });

  final String countryCode;
  final String text;
  final String version;
  final String contentHash;
}

class MoveTermsConfigurationException implements Exception {
  const MoveTermsConfigurationException(this.message);
  final String message;

  @override
  String toString() => 'MoveTermsConfigurationException: $message';
}

abstract interface class TermsConfigurationRepository {
  bool get isOnboardingEnabled;

  /// Devuelve la configuración coordinada con backend.
  ///
  /// Lanza [MoveTermsConfigurationException] si el feature está apagado,
  /// el país no es CO/CL o el artefacto de release está incompleto.
  MoveTermsConfiguration configurationFor(String countryCode);
}
