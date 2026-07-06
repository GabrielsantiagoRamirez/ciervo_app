/// Helpers para parsear tarjetas wallet Kids desde el API.
class ChildWalletCardView {
  const ChildWalletCardView({
    required this.id,
    required this.displayName,
    required this.balance,
    required this.currency,
    required this.isPrimary,
    required this.isBlocked,
    this.createdAt,
  });

  factory ChildWalletCardView.fromMap(Map<String, dynamic> json) {
    final source = _unwrapCardJson(json);
    return ChildWalletCardView(
      id: _id(source),
      displayName: _optional(source, const [
            'displayName',
            'DisplayName',
            'name',
            'Name',
            'cardName',
            'templateName',
          ]) ??
          'Tarjeta Kids',
      balance: _amount(source),
      currency: _optional(source, const ['currency', 'Currency']) ?? 'COP',
      isPrimary: _bool(source, const ['isPrimary', 'IsPrimary']),
      isBlocked: _isBlocked(source),
      createdAt: _optional(source, const ['createdAt', 'CreatedAt']),
    );
  }

  final String id;
  final String displayName;
  final double balance;
  final String currency;
  final bool isPrimary;
  final bool isBlocked;
  final String? createdAt;

  String get subtitle {
    final parts = <String>[
      'ID #$id',
      if (isPrimary) 'Principal',
      if (isBlocked) 'Bloqueada',
    ];
    return parts.join(' · ');
  }

  static List<ChildWalletCardView> listFrom(dynamic value) {
    final items = _items(value);
    return items
        .whereType<Map>()
        .map((e) => ChildWalletCardView.fromMap(Map<String, dynamic>.from(e)))
        .where((c) => c.id.isNotEmpty)
        .toList();
  }

  static Map<String, dynamic> _unwrapCardJson(Map<String, dynamic> json) {
    for (final key in const ['card', 'Card', 'value', 'Value']) {
      final nested = json[key];
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
    }
    return json;
  }

  static List<dynamic> _items(dynamic value) {
    if (value is List) return value;
    if (value is Map<String, dynamic>) {
      for (final key in const ['cards', 'Cards', 'items', 'Items']) {
        final nested = value[key];
        if (nested is List) return nested;
      }
      if (_id(_unwrapCardJson(value)).isNotEmpty) {
        return [value];
      }
    }
    return const [];
  }

  static String _id(Map<String, dynamic> json) {
    final raw = json['id'] ??
        json['Id'] ??
        json['cardId'] ??
        json['CardId'] ??
        json['walletCardId'] ??
        json['WalletCardId'] ??
        json['childWalletCardId'] ??
        json['ChildWalletCardId'];
    return raw?.toString() ?? '';
  }

  static String? _optional(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  static double _amount(Map<String, dynamic> json) {
    for (final key in const [
      'availableBalance',
      'AvailableBalance',
      'balance',
      'Balance',
    ]) {
      final value = json[key];
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static bool _bool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value != null) return value.toString().toLowerCase() == 'true';
    }
    return false;
  }

  /// Alineado con [WalletCardDto]: statusId 0 = bloqueada; 2 = creada (activa).
  static bool _isBlocked(Map<String, dynamic> json) {
    if (json['isBlocked'] == true || json['isBlocked'] == 'true') {
      return true;
    }
    final blockedAt = _optional(json, const ['blockedAt', 'BlockedAt']);
    if (blockedAt != null) return true;
    final statusId = json['statusId'] ?? json['StatusId'];
    if (statusId == 0 || statusId == '0') return true;
    final status =
        _optional(json, const ['status', 'Status', 'statusName'])?.toLowerCase() ??
            '';
    return status.contains('block');
  }
}
