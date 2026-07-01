/// Utilidades para QR y payloads de CIERVO ID.
abstract final class CiervoIdQr {
  static final _codePattern = RegExp(r'CIERVO-[A-Z0-9-]+', caseSensitive: false);

  static String payloadForCode(String code) {
    final normalized = code.trim().toUpperCase();
    return 'ciervo://user/$normalized';
  }

  /// Extrae un CIERVO ID desde texto plano, URI o JSON simple.
  static String? parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final direct = _codePattern.firstMatch(trimmed);
    if (direct != null) return direct.group(0)!.toUpperCase();

    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      if (uri.scheme == 'ciervo' && uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last;
        final fromUri = _codePattern.firstMatch(last);
        if (fromUri != null) return fromUri.group(0)!.toUpperCase();
      }
      final queryCode = uri.queryParameters['ciervoUserCode'] ??
          uri.queryParameters['code'];
      if (queryCode != null) {
        final fromQuery = _codePattern.firstMatch(queryCode);
        if (fromQuery != null) return fromQuery.group(0)!.toUpperCase();
      }
    }

    if (trimmed.contains('ciervoUserCode')) {
      final fromJson = _codePattern.firstMatch(trimmed);
      if (fromJson != null) return fromJson.group(0)!.toUpperCase();
    }

    return null;
  }
}
