import '../../domain/entities/financial_history_item.dart';

class FinancialHistoryItemDto {
  const FinancialHistoryItemDto({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.date,
    required this.description,
  });

  factory FinancialHistoryItemDto.fromJson(Map<String, dynamic> json) =>
      FinancialHistoryItemDto(
        id: _s(json, const ['id', 'movementId', 'transactionId']),
        type: _s(json, const ['type', 'movementType']),
        amount: _d(json, const ['amount', 'value']),
        currency: _s(json, const ['currency', 'currencyCode']).isEmpty
            ? 'COP'
            : _s(json, const ['currency', 'currencyCode']),
        date: DateTime.tryParse(_s(json, const ['createdAt', 'date'])),
        description: _s(json, const ['description', 'concept']),
      );

  final String id;
  final String type;
  final double amount;
  final String currency;
  final DateTime? date;
  final String description;

  FinancialHistoryItem toDomain() => FinancialHistoryItem(
    id: id,
    type: type,
    amount: amount,
    currency: currency,
    date: date,
    description: description,
  );

  static List<FinancialHistoryItemDto> listFrom(dynamic value) {
    final source = value is Map<String, dynamic>
        ? value['value'] ?? value['data'] ?? value
        : value;
    final items = source is List
        ? source
        : source is Map<String, dynamic> && source['items'] is List
        ? source['items'] as List
        : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(FinancialHistoryItemDto.fromJson)
        .toList();
  }

  static String _s(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
    return '';
  }

  static double _d(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }
}
