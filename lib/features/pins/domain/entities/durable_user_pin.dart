class DurableUserPin {
  const DurableUserPin({
    required this.code,
    required this.ownerUserId,
    required this.walletCardId,
    required this.currency,
    required this.validFrom,
    required this.expiresAt,
    this.paymentPinId,
  });

  final String code;
  final String ownerUserId;
  final String walletCardId;
  final String currency;
  final DateTime validFrom;
  final DateTime expiresAt;
  final String? paymentPinId;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt.toUtc());

  Duration get remaining => expiresAt.toUtc().difference(DateTime.now().toUtc());

  Map<String, dynamic> toJson() => {
    'code': code,
    'ownerUserId': ownerUserId,
    'walletCardId': walletCardId,
    'currency': currency,
    'validFrom': validFrom.toUtc().toIso8601String(),
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    if (paymentPinId != null) 'paymentPinId': paymentPinId,
  };

  factory DurableUserPin.fromJson(Map<String, dynamic> json) => DurableUserPin(
    code: '${json['code'] ?? json['pin'] ?? ''}',
    ownerUserId: '${json['ownerUserId'] ?? ''}',
    walletCardId: '${json['walletCardId'] ?? ''}',
    currency: '${json['currency'] ?? 'COP'}',
    validFrom:
        DateTime.tryParse('${json['validFrom'] ?? ''}')?.toUtc() ??
        DateTime.now().toUtc(),
    expiresAt:
        DateTime.tryParse('${json['expiresAt'] ?? ''}')?.toUtc() ??
        DateTime.now().toUtc(),
    paymentPinId:
        json['paymentPinId']?.toString() ?? json['remotePinId']?.toString(),
  );
}
