import 'dart:convert';
import 'dart:typed_data';

/// Token ofuscado para compartir comercios (ofuscación client-side, no secreto de servidor).
abstract final class CiervoBusinessShareLink {
  static const _key = 'CiervoClubShare2026';

  static String build({required String businessId, String? name}) {
    final token = encode(businessId);
    final uri = Uri(
      scheme: 'https',
      host: 'ciervo.club',
      pathSegments: ['b', token],
    );
    final title = (name ?? '').trim();
    if (title.isEmpty) return uri.toString();
    return '$title\n$uri';
  }

  static String encode(String businessId) {
    final plain = utf8.encode('biz:${businessId.trim()}');
    final key = utf8.encode(_key);
    final out = Uint8List(plain.length);
    for (var i = 0; i < plain.length; i++) {
      out[i] = plain[i] ^ key[i % key.length];
    }
    return base64Url.encode(out).replaceAll('=', '');
  }

  static String? decode(String token) {
    try {
      var padded = token.trim();
      final mod = padded.length % 4;
      if (mod > 0) padded = padded.padRight(padded.length + (4 - mod), '=');
      final bytes = base64Url.decode(padded);
      final key = utf8.encode(_key);
      final out = Uint8List(bytes.length);
      for (var i = 0; i < bytes.length; i++) {
        out[i] = bytes[i] ^ key[i % key.length];
      }
      final plain = utf8.decode(out);
      if (!plain.startsWith('biz:')) return null;
      final id = plain.substring(4).trim();
      return id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }

  /// Extrae businessId desde `https://ciervo.club/b/{token}` o `ciervo://b/{token}`.
  static String? businessIdFromPathSegments(List<String> segments) {
    final clean = segments.where((s) => s.isNotEmpty).toList();
    if (clean.isEmpty) return null;
    var start = 0;
    if (clean.first.toLowerCase() == 'app') start = 1;
    if (clean.length < start + 2) return null;
    final root = clean[start].toLowerCase();
    if (root != 'b' && root != 'business') return null;
    return decode(clean[start + 1]);
  }
}
