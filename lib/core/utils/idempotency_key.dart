import 'dart:math';

/// Genera claves de idempotencia para operaciones financieras.
abstract final class IdempotencyKey {
  /// UUID v4 (RFC 4122) — formato exigido por el contrato de payments.
  /// El [prefix] se ignora a propósito: el contrato pide UUID v4 puro.
  static String generate([String? prefix]) {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
