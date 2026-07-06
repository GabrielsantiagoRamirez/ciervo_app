import '../../domain/entities/payment_quote.dart';
import '../../domain/entities/universal_nfc_payment.dart';

class PaymentQuoteDto {
  const PaymentQuoteDto({
    required this.subtotal,
    required this.fee,
    required this.tax,
    required this.discount,
    required this.cashback,
    required this.total,
    required this.currency,
    required this.type,
    required this.paymentMethod,
    required this.feeApplies,
    this.feePercentage,
    this.availableBalance,
    this.sufficientFunds = true,
  });

  factory PaymentQuoteDto.fromJson(Map<String, dynamic> json) {
    return PaymentQuoteDto(
      subtotal: _num(json['subtotal']),
      fee: _num(json['fee']),
      tax: _num(json['tax']),
      discount: _num(json['discount']),
      cashback: _num(json['cashback']),
      total: _num(json['total']),
      currency: _string(json['currency'], fallback: 'COP'),
      type: _string(json['type']),
      paymentMethod: _string(json['paymentMethod'] ?? json['paymentMethodId']),
      feeApplies: json['feeApplies'] == true,
      feePercentage: _nullableNum(json['feePercentage']),
      availableBalance: _nullableNum(json['availableBalance']),
      sufficientFunds: json['sufficientFunds'] != false,
    );
  }

  PaymentQuote toDomain() => PaymentQuote(
        subtotal: subtotal,
        fee: fee,
        tax: tax,
        discount: discount,
        cashback: cashback,
        total: total,
        currency: currency,
        type: type,
        paymentMethod: paymentMethod,
        feeApplies: feeApplies,
        feePercentage: feePercentage,
        availableBalance: availableBalance,
        sufficientFunds: sufficientFunds,
      );

  final double subtotal;
  final double fee;
  final double tax;
  final double discount;
  final double cashback;
  final double total;
  final String currency;
  final String type;
  final String paymentMethod;
  final bool feeApplies;
  final double? feePercentage;
  final double? availableBalance;
  final bool sufficientFunds;
}

class SavedPaymentMethodDto {
  factory SavedPaymentMethodDto.fromJson(Map<String, dynamic> json) {
    return SavedPaymentMethodDto(
      id: _string(json['id'] ?? json['methodId']),
      type: _string(json['type'] ?? json['methodType']),
      brand: _string(json['brand'] ?? json['type']),
      status: _string(json['status'], fallback: 'active'),
      isDefault: json['isDefault'] == true || json['default'] == true,
      isTokenized: json['isTokenized'] == true || json['tokenized'] == true,
      last4: _nullableString(json['last4'] ?? json['lastFour']),
      displayName: _nullableString(json['displayName'] ?? json['alias']),
      expiryMonth: _nullableInt(json['expiryMonth'] ?? json['expirationMonth']),
      expiryYear: _nullableInt(json['expiryYear'] ?? json['expirationYear']),
    );
  }

  const SavedPaymentMethodDto({
    required this.id,
    required this.type,
    required this.brand,
    required this.status,
    required this.isDefault,
    required this.isTokenized,
    this.last4,
    this.displayName,
    this.expiryMonth,
    this.expiryYear,
  });

  SavedPaymentMethod toDomain() => SavedPaymentMethod(
        id: id,
        type: type,
        brand: brand,
        status: status,
        isDefault: isDefault,
        isTokenized: isTokenized,
        last4: last4,
        displayName: displayName,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
      );

  static List<SavedPaymentMethodDto> listFrom(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => SavedPaymentMethodDto.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();
    }
    if (value is Map) {
      final items = value['items'] ?? value['methods'] ?? value['paymentMethods'];
      if (items is List) return listFrom(items);
    }
    return const [];
  }

  final String id;
  final String type;
  final String brand;
  final String status;
  final bool isDefault;
  final bool isTokenized;
  final String? last4;
  final String? displayName;
  final int? expiryMonth;
  final int? expiryYear;
}

class UniversalNfcPaymentDto {
  factory UniversalNfcPaymentDto.fromJson(Map<String, dynamic> json) {
    final payload = json['nfcPayload'];
    return UniversalNfcPaymentDto(
      paymentIntentId: _string(
        json['paymentIntentId'] ?? json['id'] ?? json['intentId'],
      ),
      status: _string(json['status']),
      amount: _num(json['amount'] ?? json['total']),
      currency: _string(json['currency'], fallback: 'COP'),
      nfcPayload: payload is Map ? Map<String, dynamic>.from(payload) : null,
      merchantName: _nullableString(json['merchantName']),
      subtotal: _nullableNum(json['subtotal']),
      fee: _nullableNum(json['fee']),
      total: _nullableNum(json['total']),
      receiptId: _nullableString(json['receiptId']),
      reason: _nullableString(json['reason']),
      message: _nullableString(json['message'] ?? json['msg']),
      newBalance: _nullableNum(json['newBalance']),
      approved: json['approved'] as bool?,
    );
  }

  const UniversalNfcPaymentDto({
    required this.paymentIntentId,
    required this.status,
    required this.amount,
    required this.currency,
    this.nfcPayload,
    this.merchantName,
    this.subtotal,
    this.fee,
    this.total,
    this.receiptId,
    this.reason,
    this.message,
    this.newBalance,
    this.approved,
  });

  UniversalNfcPayment toDomain() => UniversalNfcPayment(
        paymentIntentId: paymentIntentId,
        status: status,
        amount: amount,
        currency: currency,
        nfcPayload: nfcPayload,
        merchantName: merchantName,
        subtotal: subtotal,
        fee: fee,
        total: total,
        receiptId: receiptId,
        reason: reason,
        message: message,
        newBalance: newBalance,
        approved: approved,
      );

  final String paymentIntentId;
  final String status;
  final double amount;
  final String currency;
  final Map<String, dynamic>? nfcPayload;
  final String? merchantName;
  final double? subtotal;
  final double? fee;
  final double? total;
  final String? receiptId;
  final String? reason;
  final String? message;
  final double? newBalance;
  final bool? approved;
}

class KidsNfcParentApprovalDto {
  factory KidsNfcParentApprovalDto.fromJson(Map<String, dynamic> json) {
    return KidsNfcParentApprovalDto(
      paymentIntentId: _string(
        json['paymentIntentId'] ?? json['id'],
      ),
      kidId: _string(json['kidId'] ?? json['childProfileId']),
      kidName: _string(
        json['kidName'] ?? json['childName'],
        fallback: 'Menor',
      ),
      amount: _num(json['amount']),
      currency: _string(json['currency'], fallback: 'COP'),
      merchantName: _string(
        json['merchantName'] ?? json['businessName'],
        fallback: 'Comercio',
      ),
      requestedAt: _date(json['requestedAt'] ?? json['createdAt']),
      approvalId: _nullableString(json['approvalId']),
    );
  }

  const KidsNfcParentApprovalDto({
    required this.paymentIntentId,
    required this.kidId,
    required this.kidName,
    required this.amount,
    required this.currency,
    required this.merchantName,
    this.requestedAt,
    this.approvalId,
  });

  KidsNfcParentApproval toDomain() => KidsNfcParentApproval(
        paymentIntentId: paymentIntentId,
        kidId: kidId,
        kidName: kidName,
        amount: amount,
        currency: currency,
        merchantName: merchantName,
        requestedAt: requestedAt,
        approvalId: approvalId,
      );

  static List<KidsNfcParentApprovalDto> listFrom(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => KidsNfcParentApprovalDto.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();
    }
    if (value is Map) {
      final items = value['items'] ?? value['approvals'];
      if (items is List) return listFrom(items);
    }
    return const [];
  }

  final String paymentIntentId;
  final String kidId;
  final String kidName;
  final double amount;
  final String currency;
  final String merchantName;
  final DateTime? requestedAt;
  final String? approvalId;
}

String _string(dynamic value, {String fallback = ''}) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return fallback;
  return text;
}

String? _nullableString(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return text;
}

double _num(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}'.replaceAll(',', '.')) ?? 0;
}

double? _nullableNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse('$value'.replaceAll(',', '.'));
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse('$value');
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
