import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/onboarding/move_terms_configuration.dart';
import 'sha256.dart';

class ReleaseTermsConfigurationRepository
    implements TermsConfigurationRepository {
  const ReleaseTermsConfigurationRepository(this._config);

  final AppConfig _config;

  static final _sha256Pattern = RegExp(r'^[a-fA-F0-9]{64}$');

  static const _devTermsText =
      'Términos MOVE Driver (borrador de desarrollo). '
      'Este texto solo se usa fuera de release para permitir completar el '
      'formulario de alta. En producción debe reemplazarse por el artefacto '
      'legal coordinado con backend.';

  @override
  bool get isOnboardingEnabled => _config.moveOnboardingEnabled;

  @override
  MoveTermsConfiguration configurationFor(String countryCode) {
    final code = countryCode.trim().toUpperCase();
    if (code != 'CO' && code != 'CL') {
      throw const MoveTermsConfigurationException(
        'País no admitido por MOVE.',
      );
    }

    if (!isOnboardingEnabled) {
      if (!kReleaseMode) return _devTerms(code);
      throw const MoveTermsConfigurationException(
        'El onboarding MOVE no está habilitado para este release.',
      );
    }

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
      if (!kReleaseMode) return _devTerms(code);
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
        if (!kReleaseMode) return _devTerms(code);
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

  MoveTermsConfiguration _devTerms(String countryCode) {
    const text = _devTermsText;
    return MoveTermsConfiguration(
      countryCode: countryCode,
      text: text,
      version: 'dev-local',
      contentHash: sha256Hex(text),
    );
  }
}
