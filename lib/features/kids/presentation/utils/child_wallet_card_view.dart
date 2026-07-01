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
    final blockedAt = _optional(json, const ['blockedAt', 'BlockedAt']);
    final statusId = json['statusId'] ?? json['StatusId'];
    return ChildWalletCardView(
      id: _id(json),
      displayName: _optional(json, const ['displayName', 'DisplayName']) ??
          'Tarjeta Kids',
      balance: _amount(json),
      currency: _optional(json, const ['currency', 'Currency']) ?? 'COP',
      isPrimary: _bool(json, const ['isPrimary', 'IsPrimary']),
      isBlocked: blockedAt != null ||
          statusId == 2 ||
          statusId == '2',
      createdAt: _optional(json, const ['createdAt', 'CreatedAt']),
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
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => ChildWalletCardView.fromMap(Map<String, dynamic>.from(e)))
          .where((c) => c.id.isNotEmpty)
          .toList();
    }
    if (value is Map<String, dynamic>) {
      final cards = value['cards'] ?? value['Cards'];
      if (cards is List) return listFrom(cards);
    }
    return const [];
  }

  static String _id(Map<String, dynamic> json) {
    final raw = json['id'] ?? json['Id'] ?? json['cardId'] ?? json['CardId'];
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
}
