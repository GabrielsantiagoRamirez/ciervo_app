import '../../domain/entities/payment_request.dart';

class PaymentRequestDto {
  const PaymentRequestDto({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.description,
    this.payerName,
    this.targetName,
    this.createdAt,
    this.expiresAt,
  });

  factory PaymentRequestDto.fromJson(Map<String, dynamic> json) {
    return PaymentRequestDto(
      id: _string(json, const ['id', 'paymentRequestId']),
      amount: _double(json, const ['amount', 'value']),
      currency: _string(json, const ['currency', 'currencyCode']).isEmpty
          ? 'COP'
          : _string(json, const ['currency', 'currencyCode']),
      status: _string(json, const ['status', 'statusName']).isEmpty
          ? _string(json, const ['statusId'])
          : _string(json, const ['status', 'statusName']),
      description: _string(json, const ['description', 'purpose', 'message']),
      payerName: _optionalString(json, const ['payerName', 'payerFullName']),
      targetName: _optionalString(json, const ['targetName', 'targetFullName']),
      createdAt: DateTime.tryParse(_string(json, const ['createdAt', 'date'])),
      expiresAt: DateTime.tryParse(_string(json, const ['expiresAt'])),
    );
  }

  final String id;
  final double amount;
  final String currency;
  final String status;
  final String description;
  final String? payerName;
  final String? targetName;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  PaymentRequest toDomain() => PaymentRequest(
    id: id,
    amount: amount,
    currency: currency,
    status: status.isEmpty ? 'Pendiente' : status,
    description: description,
    payerName: payerName,
    targetName: targetName,
    createdAt: createdAt,
    expiresAt: expiresAt,
  );

  static List<PaymentRequestDto> listFrom(dynamic value) {
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
        .map(PaymentRequestDto.fromJson)
        .toList();
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
