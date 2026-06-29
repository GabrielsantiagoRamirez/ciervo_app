import '../../domain/entities/receipt.dart';

class ReceiptDto {
  const ReceiptDto({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.date,
    required this.status,
    this.description,
    this.userCiervoCode,
    this.publicReceiptUrl,
    this.shareTitle,
    this.shareDescription,
  });

  factory ReceiptDto.fromJson(Map<String, dynamic> json) {
    return ReceiptDto(
      id: _string(json, const ['id', 'receiptId']),
      title: _string(json, const ['title', 'concept', 'type']).isEmpty
          ? 'Recibo'
          : _string(json, const ['title', 'concept', 'type']),
      amount: _double(json, const ['amount', 'total', 'value']),
      currency: _string(json, const ['currency', 'currencyCode']).isEmpty
          ? 'COP'
          : _string(json, const ['currency', 'currencyCode']),
      date: DateTime.tryParse(_string(json, const ['createdAt', 'date'])),
      status: _string(json, const ['status']).isEmpty
          ? 'completed'
          : _string(json, const ['status']),
      description: _string(json, const ['description', 'message']),
      userCiervoCode: _stringOrNull(json, const [
        'userCiervoCode',
        'userPublicCode',
        'ciervoUserCode',
      ]),
      publicReceiptUrl: _stringOrNull(json, const ['publicReceiptUrl']),
      shareTitle: _stringOrNull(json, const ['shareTitle']),
      shareDescription: _stringOrNull(json, const ['shareDescription']),
    );
  }

  final String id;
  final String title;
  final double amount;
  final String currency;
  final DateTime? date;
  final String status;
  final String? description;
  final String? userCiervoCode;
  final String? publicReceiptUrl;
  final String? shareTitle;
  final String? shareDescription;

  Receipt toDomain() => Receipt(
    id: id,
    title: title,
    amount: amount,
    currency: currency,
    date: date,
    status: status,
    description: description,
    userCiervoCode: userCiervoCode,
    publicReceiptUrl: publicReceiptUrl,
    shareTitle: shareTitle,
    shareDescription: shareDescription,
  );

  static List<ReceiptDto> listFrom(dynamic value) {
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
        .map(ReceiptDto.fromJson)
        .toList();
  }

  static String? _stringOrNull(Map<String, dynamic> json, List<String> keys) {
    final value = _string(json, keys);
    return value.isEmpty ? null : value;
  }

  static String _string(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
    return '';
  }

  static double _double(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }
}
