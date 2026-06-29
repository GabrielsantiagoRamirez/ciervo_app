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
      debugPrint('CIERVO ERROR: $message\n$error\n$stackTrace');
    }
  }

  void _log(String level, String message, [Object? error]) {
    if (!_config.environment.enablesVerboseLogs) {
      return;
    }
    final suffix = error == null ? '' : ' | $error';
    debugPrint('CIERVO $level: $message$suffix');
  }
}
