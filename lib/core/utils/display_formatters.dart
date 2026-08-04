import 'display_labels.dart';

/// Helpers de presentación para evitar nulls, IDs técnicos y montos sin formato.
abstract final class DisplayFormatters {
  /// Convierte null, "null" o vacío en [fallback].
  static String safeText(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return fallback;
    return text;
  }

  /// Nombre visible con cadena de fallback estándar Ciervo.
  static String safeDisplayName({
    String? nickname,
    String? displayName,
    String? firstName,
    String? lastName,
    String? fullName,
    String? username,
    String? ciervoId,
    String fallback = 'Usuario',
  }) {
    final nick = safeText(nickname);
    if (nick.isNotEmpty) return nick;

    final display = safeText(displayName);
    if (display.isNotEmpty) return display;

    final composed = [
      safeText(firstName),
      safeText(lastName),
    ].where((part) => part.isNotEmpty).join(' ').trim();
    if (composed.isNotEmpty) return composed;

    final full = safeText(fullName);
    if (full.isNotEmpty) return full;

    final user = safeText(username);
    if (user.isNotEmpty) return user.startsWith('@') ? user : '@$user';

    final id = safeText(ciervoId);
    if (id.isNotEmpty) return id;

    return fallback;
  }

  /// @username sin duplicar arroba.
  static String formatUsername(String? username) {
    final text = safeText(username);
    if (text.isEmpty) return '';
    return text.startsWith('@') ? text : '@$text';
  }

  /// Línea de identidad: @usuario · Nombre · CIERVO-ID
  static String identityLine({
    String? username,
    String? displayName,
    String? firstName,
    String? lastName,
    String? ciervoId,
  }) {
    final parts = <String>[];
    final user = formatUsername(username);
    if (user.isNotEmpty) parts.add(user);

    final name = safeDisplayName(
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
      fallback: '',
    );
    if (name.isNotEmpty && name != user) parts.add(name);

    final id = safeText(ciervoId);
    if (id.isNotEmpty) parts.add(id);

    return parts.join(' · ');
  }

  static String formatMoney(num? amount, {String currency = 'COP'}) {
    final value = (amount?.toDouble() ?? 0).round();
    final sign = value < 0 ? '-' : '';
    final code = currency.trim().toUpperCase();
    return '$code $sign${groupThousands(value.abs())}';
  }

  /// Precio con símbolo `$` y separador de miles, sin decimales: `$15.000`.
  static String formatPrice(num? amount, {String symbol = '\$'}) {
    final value = (amount?.toDouble() ?? 0).round();
    final sign = value < 0 ? '-' : '';
    return '$sign$symbol${groupThousands(value.abs())}';
  }

  /// Miles con punto: `20000` → `20.000`.
  static String groupThousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Parsea montos con puntos/comas de miles: `20.000` → `20000`.
  static double? parseMoneyInput(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    final cleaned = text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  static String formatStatus(String? status) =>
      DisplayLabels.paymentRequestStatus(status);

  static String formatDate(DateTime? date, {bool includeTime = false}) {
    if (date == null) return '';
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    if (!includeTime) return '$day/$month/$year';
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $h:$m';
  }

  /// Parsea fechas ISO del backend (`2026-07-06T18:56:32.227Z`).
  static DateTime? parseBackendDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return DateTime.tryParse(text);
  }

  static String formatBackendDate(Object? value, {bool includeTime = true}) =>
      formatDate(parseBackendDate(value), includeTime: includeTime);

  /// Título de chat directo o grupal.
  static String chatTitle({
    required String? rawTitle,
    String? username,
    String? displayName,
    String? firstName,
    String? lastName,
    String? conversationType,
    String? businessName,
    int? participantCount,
  }) {
    final type = safeText(conversationType).toLowerCase();
    final business = safeText(businessName);
    if ((type.contains('business') || business.isNotEmpty) &&
        business.isNotEmpty) {
      return business;
    }

    if (type.contains('direct')) {
      final line = identityLine(
        username: username,
        displayName: displayName,
        firstName: firstName,
        lastName: lastName,
      );
      if (line.isNotEmpty) return line;
    }

    var title = safeText(rawTitle, fallback: '');
    // Evita títulos genéricos tipo "Consulta Nuevo negocio..."
    if (title.toLowerCase().startsWith('consulta ')) {
      title = title.substring('consulta '.length).trim();
    }
    if (title.isNotEmpty && !_looksLikeRawId(title)) return title;

    if (type.contains('family')) return 'Chat familiar';
    if (type.contains('business')) {
      return business.isNotEmpty ? business : 'Chat comercial';
    }
    if (type.contains('group') &&
        participantCount != null &&
        participantCount > 0) {
      return '$title ($participantCount)';
    }

    return title.isEmpty ? 'Conversación' : title;
  }

  static bool _looksLikeRawId(String value) {
    if (RegExp(r'^\d+$').hasMatch(value)) return true;
    if (value.contains('could not be translated')) return true;
    return false;
  }
}
