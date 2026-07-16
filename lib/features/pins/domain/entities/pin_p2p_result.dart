class PinP2PVerifyResult {
  const PinP2PVerifyResult({
    required this.valid,
    this.payerName,
    this.currency,
    this.amount,
    this.message,
  });

  factory PinP2PVerifyResult.fromJson(Map<String, dynamic> json) {
    final status = json['status'] ?? json['valid'];
    final valid = status == true || status == 'true' || status == 1;
    return PinP2PVerifyResult(
      valid: valid || json['isValid'] == true,
      payerName: _optional(json, const ['payerName', 'ownerName', 'name']),
      currency: _optional(json, const ['currency', 'currencyCode']),
      amount: _num(json['amount']),
      message: _optional(json, const ['message', 'msg']),
    );
  }

  final bool valid;
  final String? payerName;
  final String? currency;
  final num? amount;
  final String? message;

  static String? _optional(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  static num? _num(dynamic value) {
    if (value is num) return value;
    return num.tryParse('$value');
  }
}

class PinP2PPayResult {
  const PinP2PPayResult({
    required this.success,
    this.transactionId,
    this.receiptId,
    this.amount,
    this.currency,
    this.message,
  });

  factory PinP2PPayResult.fromJson(Map<String, dynamic> json) {
    return PinP2PPayResult(
      success: json['success'] != false,
      transactionId: _optional(json, const [
        'transactionId',
        'transferId',
        'paymentId',
        'id',
      ]),
      receiptId: _optional(json, const ['receiptId', 'receiptCode']),
      amount: _num(json['amount']),
      currency: _optional(json, const ['currency', 'currencyCode']),
      message: _optional(json, const ['message', 'msg']),
    );
  }

  final bool success;
  final String? transactionId;
  final String? receiptId;
  final num? amount;
  final String? currency;
  final String? message;

  static String? _optional(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  static num? _num(dynamic value) {
    if (value is num) return value;
    return num.tryParse('$value');
  }
}
