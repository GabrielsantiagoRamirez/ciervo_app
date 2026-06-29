import '../../domain/entities/payment_config.dart';
import '../../domain/entities/payment_history_item.dart';
import '../../domain/entities/payment_intent.dart';

class PaymentConfigDto {
  const PaymentConfigDto({
    required this.provider,
    required this.enabled,
    required this.isSandbox,
    required this.publicKey,
    required this.currency,
    this.successUrl,
    this.failureUrl,
    this.pendingUrl,
  });

  factory PaymentConfigDto.fromJson(Map<String, dynamic> json) {
    return PaymentConfigDto(
      provider: _string(json, const ['provider']),
      enabled: _bool(json, const ['enabled'], defaultValue: true),
      isSandbox: _bool(json, const ['isSandbox', 'sandbox']),
      publicKey: _string(json, const ['publicKey', 'public_key']),
      currency: _string(json, const ['currency']).isEmpty
          ? 'COP'
          : _string(json, const ['currency']),
      successUrl: _stringOrNull(json, const ['successUrl']),
      failureUrl: _stringOrNull(json, const ['failureUrl']),
      pendingUrl: _stringOrNull(json, const ['pendingUrl']),
    );
  }

  final String provider;
  final bool enabled;
  final bool isSandbox;
  final String publicKey;
  final String currency;
  final String? successUrl;
  final String? failureUrl;
  final String? pendingUrl;

  PaymentConfig toDomain() => PaymentConfig(
        provider: provider,
        enabled: enabled,
        isSandbox: isSandbox,
        publicKey: publicKey,
        currency: currency,
        successUrl: successUrl,
        failureUrl: failureUrl,
        pendingUrl: pendingUrl,
      );
}

class PaymentIntentDto {
  const PaymentIntentDto({
    required this.id,
    required this.type,
    required this.status,
    required this.checkoutUrl,
    this.amount,
    this.currency,
    this.membershipPlanId,
    this.receiptUrl,
  });

  factory PaymentIntentDto.fromJson(Map<String, dynamic> json) {
    return PaymentIntentDto(
      id: _string(json, const [
        'paymentIntentId',
        'id',
        'intentId',
      ]),
      type: _string(json, const ['type']),
      status: _string(json, const ['status']).isEmpty
          ? 'pending'
          : _string(json, const ['status']),
      checkoutUrl: _string(json, const [
        'checkoutUrl',
        'initPoint',
        'init_point',
      ]),
      amount: _double(json, const ['amount', 'localChargeAmount']),
      currency: _stringOrNull(json, const ['currency', 'localChargeCurrency']),
      membershipPlanId: _stringOrNull(json, const [
        'membershipPlanId',
        'planId',
      ]),
      receiptUrl: _stringOrNull(json, const [
        'publicReceiptUrl',
        'receiptUrl',
      ]),
    );
  }

  final String id;
  final String type;
  final String status;
  final String checkoutUrl;
  final double? amount;
  final String? currency;
  final String? membershipPlanId;
  final String? receiptUrl;

  PaymentIntent toDomain() => PaymentIntent(
        id: id,
        type: type,
        status: status,
        checkoutUrl: checkoutUrl,
        amount: amount,
        currency: currency,
        membershipPlanId: membershipPlanId,
        receiptUrl: receiptUrl,
      );
}

class PaymentHistoryItemDto {
  const PaymentHistoryItemDto({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    this.createdAt,
    this.receiptUrl,
  });

  factory PaymentHistoryItemDto.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItemDto(
      id: _string(json, const ['paymentIntentId', 'id']),
      type: _string(json, const ['type']),
      status: _string(json, const ['status']),
      amount: _double(json, const ['amount']),
      currency: _string(json, const ['currency']).isEmpty
          ? 'COP'
          : _string(json, const ['currency']),
      createdAt: _stringOrNull(json, const ['createdAt', 'paidAt']),
      receiptUrl: _stringOrNull(json, const [
        'publicReceiptUrl',
        'receiptUrl',
      ]),
    );
  }

  final String id;
  final String type;
  final String status;
  final double amount;
  final String currency;
  final String? createdAt;
  final String? receiptUrl;

  PaymentHistoryItem toDomain() => PaymentHistoryItem(
        id: id,
        type: type,
        status: status,
        amount: amount,
        currency: currency,
        createdAt: createdAt,
        receiptUrl: receiptUrl,
      );

  static List<PaymentHistoryItemDto> listFrom(dynamic value) {
    final items = value is List
        ? value
        : value is Map<String, dynamic> && value['items'] is List
            ? value['items'] as List
            : const [];
    return items
        .whereType<Map>()
        .map((item) => PaymentHistoryItemDto.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }
}

String _string(Map<String, dynamic> json, List<String> keys) =>
    _stringOrNull(json, keys) ?? '';

String? _stringOrNull(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) {
      return value.toString();
    }
  }
  return null;
}

double _double(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse('${value ?? ''}');
    if (parsed != null) return parsed;
  }
  return 0;
}

bool _bool(
  Map<String, dynamic> json,
  List<String> keys, {
  bool defaultValue = false,
}) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value != null) return value.toString().toLowerCase() == 'true';
  }
  return defaultValue;
}
