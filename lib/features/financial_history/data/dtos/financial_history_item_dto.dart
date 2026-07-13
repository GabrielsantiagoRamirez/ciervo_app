import '../../domain/entities/financial_history_item.dart';

class FinancialHistoryItemDto {
  const FinancialHistoryItemDto({
    required this.id,
    required this.source,
    required this.sourceId,
    required this.type,
    required this.direction,
    required this.amount,
    required this.currency,
    required this.status,
    required this.date,
    required this.description,
    this.receiptId,
    this.paymentIntentId,
    this.referenceType,
    this.referenceId,
    this.balanceBefore,
    this.balanceAfter,
  });

  factory FinancialHistoryItemDto.fromJson(Map<String, dynamic> json) {
    final sourceId = _i(json, const [
      'sourceId',
      'id',
      'movementId',
      'transactionId',
    ]);
    final source = _s(json, const ['source']).isEmpty
        ? 'movement'
        : _s(json, const ['source']);
    return FinancialHistoryItemDto(
      id: sourceId > 0 ? '$source:$sourceId' : _s(json, const ['id']),
      source: source,
      sourceId: sourceId,
      type: _s(json, const ['type', 'movementType']),
      direction: _s(json, const ['direction']),
      amount: _d(json, const ['amount', 'value']),
      currency: _s(json, const ['currency', 'currencyCode']).isEmpty
          ? 'COP'
          : _s(json, const ['currency', 'currencyCode']),
      status: _s(json, const ['status']),
      date: DateTime.tryParse(_s(json, const ['createdAt', 'date'])),
      description: _s(json, const ['description', 'concept']),
      receiptId: _iOrNull(json, const ['receiptId']),
      paymentIntentId: _iOrNull(json, const ['paymentIntentId']),
      referenceType: _sOrNull(json, const ['referenceType']),
      referenceId: _sOrNull(json, const ['referenceId']),
      balanceBefore: _dOrNull(json, const ['balanceBefore']),
      balanceAfter: _dOrNull(json, const ['balanceAfter']),
    );
  }

  final String id;
  final String source;
  final int sourceId;
  final String type;
  final String direction;
  final double amount;
  final String currency;
  final String status;
  final DateTime? date;
  final String description;
  final int? receiptId;
  final int? paymentIntentId;
  final String? referenceType;
  final String? referenceId;
  final double? balanceBefore;
  final double? balanceAfter;

  FinancialHistoryItem toDomain() => FinancialHistoryItem(
    id: id,
    source: source,
    sourceId: sourceId,
    type: type,
    direction: direction,
    amount: amount,
    currency: currency,
    status: status,
    date: date,
    description: description,
    receiptId: receiptId,
    paymentIntentId: paymentIntentId,
    referenceType: referenceType,
    referenceId: referenceId,
    balanceBefore: balanceBefore,
    balanceAfter: balanceAfter,
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

  static String? _sOrNull(Map<String, dynamic> json, List<String> keys) {
    final value = _s(json, keys);
    return value.isEmpty ? null : value;
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

  static double? _dOrNull(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static int _i(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static int? _iOrNull(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is int) return value;
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }
}
