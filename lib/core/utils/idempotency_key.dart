import 'dart:math';

/// Genera claves de idempotencia para operaciones financieras.
abstract final class IdempotencyKey {
  static String generate([String prefix = 'ciervo']) {
    final random = Random.secure().nextInt(1 << 32);
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$random';
  }
}
