import '../../domain/entities/wallet_transaction.dart';

class WalletTransactionDto {
  const WalletTransactionDto({
    required this.id,
    required this.type,
    required this.direction,
    required this.amount,
    required this.currency,
    required this.description,
    required this.createdAt,
    this.balanceBefore,
    this.balanceAfter,
  });

  factory WalletTransactionDto.fromJson(Map<String, dynamic> json) {
    return WalletTransactionDto(
      id: _string(json, const ['id', 'transactionId']),
      type: _string(json, const ['type', 'transactionType']),
      direction: _string(json, const ['direction', 'movementDirection']),
      amount: _double(json, const ['amount', 'value']),
      currency: _string(json, const ['currency', 'currencyCode']).isEmpty
          ? 'COP'
          : _string(json, const ['currency', 'currencyCode']),
      description: _string(json, const ['description', 'concept']),
      createdAt: DateTime.tryParse(_string(json, const ['createdAt', 'date'])),
      balanceBefore: _optionalDouble(json, const ['balanceBefore']),
      balanceAfter: _optionalDouble(json, const ['balanceAfter']),
    );
  }

  final String id;
  final String type;
  final String direction;
  final double amount;
  final String currency;
  final String description;
  final DateTime? createdAt;
  final double? balanceBefore;
  final double? balanceAfter;

  WalletTransaction toDomain() => WalletTransaction(
    id: id,
    type: type,
    direction: direction,
    amount: amount,
    currency: currency,
    description: description,
    createdAt: createdAt,
    balanceBefore: balanceBefore,
    balanceAfter: balanceAfter,
  );

  static List<WalletTransactionDto> listFrom(dynamic value) {
    final items = value is List
        ? value
        : value is Map<String, dynamic> &&
              (value['value'] ?? value['data']) is List
        ? (value['value'] ?? value['data']) as List
        : value is Map<String, dynamic> &&
              (value['value'] ?? value['data']) is Map<String, dynamic> &&
              ((value['value'] ?? value['data'])
                      as Map<String, dynamic>)['items']
                  is List
        ? ((value['value'] ?? value['data']) as Map<String, dynamic>)['items']
              as List
        : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(WalletTransactionDto.fromJson)
        .toList();
  }

  static String _string(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
    return '';
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
}
