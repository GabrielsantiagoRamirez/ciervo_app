import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../config/app_environment.dart';

class AppLogger {
  AppLogger(this._config);

  final AppConfig _config;

  void info(String message) {
    _log('INFO', message);
  }

  void warning(String message, [Object? error]) {
    _log('WARN', message, error);
  }

  void error(String message, Object error, StackTrace stackTrace) {
    if (_config.environment.enablesVerboseLogs) {
      debugPrint(
        'CIERVO ERROR: ${sanitizeForLog(message)}\n'
        '${sanitizeForLog(error.toString())}\n'
        '${sanitizeForLog(stackTrace.toString())}',
      );
    }
  }

  void _log(String level, String message, [Object? error]) {
    if (!_config.environment.enablesVerboseLogs) {
      return;
    }
    final suffix = error == null ? '' : ' | ${sanitizeForLog('$error')}';
    debugPrint('CIERVO $level: ${sanitizeForLog(message)}$suffix');
  }
}

String sanitizeForLog(String value) {
  var sanitized = value;
  sanitized = sanitized.replaceAllMapped(
    RegExp(
      r'(authorization\s*[:=]\s*bearer\s+)[^\s,;}]+',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)}[REDACTED]',
  );
  sanitized = sanitized.replaceAll(
    RegExp(r'[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}'),
    '[REDACTED_JWT]',
  );
  sanitized = sanitized.replaceAllMapped(
    RegExp(
      r'''(["']?(?:accessToken|refreshToken|firebaseIdToken|fcmToken|token|externalProviderToken|providerToken|pin|merchantQr|payloadNfc)["']?\s*[:=]\s*["']?)([^"',}\s]+)''',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)}[REDACTED]',
  );
  sanitized = sanitized.replaceAllMapped(
    RegExp(
      r'''(["']?(?:firstNames|lastNames|fullName|documentNumber|licenseNumber|number|plate|vin|email|phone|emergencyName|emergencyPhone|accountLast4|birthDate|scheduleJson)["']?\s*[:=]\s*)(["'][^"']*["']|[^,}\s]+)''',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)}"[REDACTED_PII]"',
  );
  sanitized = sanitized.replaceAllMapped(
    RegExp(
      r'''(["']?(?:file|bytes|image|media|multipartFile)["']?\s*[:=]\s*)([^,}\n]+)''',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)}[REDACTED_MEDIA]',
  );
  return sanitized;
}
