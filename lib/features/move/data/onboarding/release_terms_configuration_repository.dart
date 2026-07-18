import 'dart:convert';

import '../../../../core/config/app_config.dart';
import '../../domain/onboarding/move_terms_configuration.dart';
import 'sha256.dart';

class ReleaseTermsConfigurationRepository
    implements TermsConfigurationRepository {
  const ReleaseTermsConfigurationRepository(this._config);

  final AppConfig _config;

  static final _sha256Pattern = RegExp(r'^[a-fA-F0-9]{64}$');

  @override
  bool get isOnboardingEnabled => _config.moveOnboardingEnabled;

  @override
  MoveTermsConfiguration configurationFor(String countryCode) {
    if (!isOnboardingEnabled) {
      throw const MoveTermsConfigurationException(
        'El onboarding MOVE no está habilitado para este release.',
      );
    }
    final code = countryCode.trim().toUpperCase();
    final (encodedText, version, hash) = switch (code) {
      'CO' => (
        _config.moveTermsCoTextBase64,
        _config.moveTermsCoVersion,
        _config.moveTermsCoContentHash,
      ),
      'CL' => (
        _config.moveTermsClTextBase64,
        _config.moveTermsClVersion,
        _config.moveTermsClContentHash,
      ),
      _ => throw const MoveTermsConfigurationException(
        'País no admitido por MOVE.',
      ),
    };
    if (encodedText.trim().isEmpty ||
        version.trim().isEmpty ||
        version.trim().length > 40 ||
        !_sha256Pattern.hasMatch(hash.trim())) {
      throw const MoveTermsConfigurationException(
        'La configuración de términos MOVE está incompleta.',
      );
    }
    try {
      final text = utf8.decode(base64Decode(encodedText.trim())).trim();
      if (text.isEmpty) {
        throw const MoveTermsConfigurationException(
          'El texto legal MOVE está vacío.',
        );
      }
      if (sha256Hex(text) != hash.trim().toLowerCase()) {
        throw const MoveTermsConfigurationException(
          'El texto legal MOVE no coincide con su hash de release.',
        );
      }
      return MoveTermsConfiguration(
        countryCode: code,
        text: text,
        version: version.trim(),
        contentHash: hash.trim().toLowerCase(),
      );
    } on FormatException {
      throw const MoveTermsConfigurationException(
        'El texto legal MOVE no es Base64 válido.',
      );
    }
  }
}
