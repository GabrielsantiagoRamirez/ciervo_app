import 'dart:convert';

/// Utilidades para validar ID tokens JWT de Firebase antes de enviarlos al backend.
abstract final class FirebaseIdToken {
  static bool isValidIdToken(String? token) {
    if (token == null || token.isEmpty) return false;
    final parts = token.split('.');
    if (parts.length != 3) return false;
    try {
      final header = decodeHeader(token);
      final kid = header['kid'];
      final alg = header['alg']?.toString();
      return kid != null &&
          kid.toString().isNotEmpty &&
          alg != null &&
          alg.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic> decodeHeader(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('JWT malformado.');
    }
    return _decodeJsonPart(parts[0]);
  }

  static Map<String, dynamic> _decodeJsonPart(String part) {
    var normalized = part.replaceAll('-', '+').replaceAll('_', '/');
    final padding = normalized.length % 4;
    if (padding > 0) {
      normalized += '=' * (4 - padding);
    }
    final decoded = utf8.decode(base64.decode(normalized));
    final json = jsonDecode(decoded);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('JWT header inválido.');
    }
    return json;
  }
}
