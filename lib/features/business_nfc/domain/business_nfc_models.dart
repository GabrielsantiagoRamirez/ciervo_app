typedef Json = Map<String, dynamic>;

class BusinessNfcCredential {
  const BusinessNfcCredential({required this.sessionId, required this.token});
  final int sessionId;
  final String token;

  factory BusinessNfcCredential.fromPayload(Json json) => BusinessNfcCredential(
    sessionId: _integer(json['s'] ?? json['sessionId']),
    token: (json['t'] ?? json['token'] ?? '').toString(),
  );
}

class BusinessNfcValidateCommand {
  const BusinessNfcValidateCommand({
    required this.sessionId,
    required this.token,
  });
  final int sessionId;
  final String token;
  Json toJson() => {'sessionId': sessionId, 'token': token};
}

class BusinessNfcChargeCommand {
  const BusinessNfcChargeCommand({
    required this.sessionId,
    required this.token,
    required this.idempotencyKey,
  });
  final int sessionId;
  final String token;
  final String idempotencyKey;
  Json toJson() => {
    'sessionId': sessionId,
    'token': token,
    'idempotencyKey': idempotencyKey,
  };
}

class BusinessNfcValidation {
  const BusinessNfcValidation({
    required this.valid,
    this.sessionId,
    this.amount,
    this.currency,
    this.customerName,
    this.description,
    this.expiresAt,
    this.reason,
  });
  final bool valid;
  final int? sessionId;
  final double? amount;
  final String? currency;
  final String? customerName;
  final String? description;
  final DateTime? expiresAt;
  final String? reason;

  factory BusinessNfcValidation.fromJson(Json json) => BusinessNfcValidation(
    valid: json['valid'] == true || json['isValid'] == true,
    sessionId: _optionalInteger(json['sessionId'] ?? json['id']),
    amount: _optionalNumber(json['amount']),
    currency: json['currency']?.toString(),
    customerName:
        json['customerName']?.toString() ?? json['userName']?.toString(),
    description: json['description']?.toString(),
    expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '')?.toUtc(),
    reason: json['reason']?.toString() ?? json['message']?.toString(),
  );
}

class BusinessNfcCharge {
  const BusinessNfcCharge({
    required this.status,
    this.transactionId,
    this.receiptId,
    this.amount,
    this.currency,
    this.newBalance,
  });
  final String status;
  final String? transactionId;
  final String? receiptId;
  final double? amount;
  final String? currency;
  final double? newBalance;

  factory BusinessNfcCharge.fromJson(Json json) => BusinessNfcCharge(
    status: json['status']?.toString() ?? 'Completed',
    transactionId: json['transactionId']?.toString(),
    receiptId: json['receiptId']?.toString(),
    amount: _optionalNumber(json['amount']),
    currency: json['currency']?.toString(),
    newBalance: _optionalNumber(json['newBalance']),
  );
}

int _integer(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value.toString()) ?? 0;

int? _optionalInteger(Object? value) => value == null ? null : _integer(value);

double? _optionalNumber(Object? value) => value is num
    ? value.toDouble()
    : value == null
    ? null
    : double.tryParse(value.toString());
