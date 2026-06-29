class NfcPayload {
  const NfcPayload({
    required this.version,
    required this.token,
    required this.sessionId,
    this.expiresAt,
    this.amount,
    this.currency,
  });

  final int version;
  final String token;
  final int sessionId;
  final DateTime? expiresAt;
  final double? amount;
  final String? currency;

  String get qrValue => token;
}

class NfcSession {
  const NfcSession({
    required this.id,
    required this.token,
    required this.status,
    this.nfcPayload,
    this.expiresAt,
    this.amount,
    this.currency,
    this.businessId,
    this.businessName,
    this.walletCardId,
    this.description,
    this.receiptId,
  });

  final int id;
  final String token;
  final String status;
  final NfcPayload? nfcPayload;
  final DateTime? expiresAt;
  final double? amount;
  final String? currency;
  final int? businessId;
  final String? businessName;
  final int? walletCardId;
  final String? description;
  final int? receiptId;

  bool get isActive => status.toLowerCase() == 'active';
  bool get isUsed => status.toLowerCase() == 'used';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isExpired =>
      status.toLowerCase() == 'expired' ||
      (expiresAt != null && DateTime.now().isAfter(expiresAt!));
}

class PhysicalNfcCard {
  const PhysicalNfcCard({
    required this.id,
    required this.cardUid,
    required this.label,
    required this.status,
    this.walletCardId,
    this.createdAt,
  });

  final int id;
  final String cardUid;
  final String label;
  final String status;
  final int? walletCardId;
  final DateTime? createdAt;

  bool get isBlocked => status.toLowerCase().contains('block');
}
