import '../../domain/entities/wallet_card.dart';

class WalletCardDto {
  const WalletCardDto({
    required this.id,
    required this.name,
    required this.balance,
    required this.heldBalance,
    required this.availableBalance,
    required this.currency,
    required this.status,
    required this.isPrimary,
    this.mask,
    this.isBlocked = false,
  });

  factory WalletCardDto.fromJson(Map<String, dynamic> json) {
    final balance = _double(json, const ['balance']);
    final heldBalance = _double(json, const ['heldBalance']);
    final available = _optionalDouble(json, const ['availableBalance']);
    final blockedAt = _optionalString(json, const ['blockedAt', 'BlockedAt']);
    final statusId = json['statusId'] ?? json['StatusId'];
    return WalletCardDto(
      id: _string(json, const ['id', 'cardId', 'walletCardId']),
      name: _string(json, const [
        'displayName',
        'name',
        'templateName',
        'cardName',
      ]),
      balance: balance,
      heldBalance: heldBalance,
      availableBalance: available ?? (balance - heldBalance),
      currency: _string(json, const ['currency', 'currencyCode']).isEmpty
          ? 'COP'
          : _string(json, const ['currency', 'currencyCode']),
      status: _statusLabel(json),
      isPrimary: _bool(json, const ['isPrimary', 'primary']),
      mask: _optionalString(json, const ['mask', 'cardMask', 'lastFour']),
      isBlocked: blockedAt != null ||
          statusId == 2 ||
          statusId == '2' ||
          _statusLabel(json).toLowerCase().contains('block'),
    );
  }

  final String id;
  final String name;
  final double balance;
  final double heldBalance;
  final double availableBalance;
  final String currency;
  final String status;
  final bool isPrimary;
  final String? mask;
  final bool isBlocked;

  WalletCard toDomain() => WalletCard(
    id: id,
    name: name.isEmpty ? 'Tarjeta Ciervo' : name,
    balance: balance,
    heldBalance: heldBalance,
    availableBalance: availableBalance,
    currency: currency,
    status: status,
    isPrimary: isPrimary,
    mask: mask,
    isBlocked: isBlocked,
  );

  static List<WalletCardDto> listFrom(dynamic value) {
    final items = _items(value);
    return items
        .whereType<Map<String, dynamic>>()
        .map(WalletCardDto.fromJson)
        .toList();
  }

  static List<dynamic> _items(dynamic value) {
    if (value is List) return value;
    if (value is Map<String, dynamic>) {
      final data = value['value'] ?? value['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic> && data['items'] is List) {
        return data['items'] as List;
      }
      if (value['items'] is List) return value['items'] as List;
    }
    return const [];
  }

  static String _string(Map<String, dynamic> json, List<String> keys) {
    return _optionalString(json, keys) ?? '';
  }

  static String? _optionalString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
    return null;
  }

  static String _statusLabel(Map<String, dynamic> json) {
    final name = _optionalString(json, const ['statusName']);
    if (name != null) return name;
    final statusId = json['statusId'];
    return statusId?.toString() ?? 'active';
  }

  static double _double(Map<String, dynamic> json, List<String> keys) {
    return _optionalDouble(json, keys) ?? 0;
  }

  static double? _optionalDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
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
