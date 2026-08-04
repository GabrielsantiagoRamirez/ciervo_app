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
    this.identifier,
    this.walletCardId,
    this.childProfileId,
    this.childWalletCardId,
    this.createdAt,
    this.blockedAt,
    this.updatedAt,
    this.canEdit = true,
    this.canBlock = true,
    this.canUnblock = false,
    this.canRevoke = true,
  });

  final int id;

  /// Identificador de plataforma (ej. NFC-00000012).
  final String? identifier;
  final String cardUid;
  final String label;
  final String status;
  final int? walletCardId;
  final int? childProfileId;
  final int? childWalletCardId;
  final DateTime? createdAt;
  final DateTime? blockedAt;
  final DateTime? updatedAt;
  final bool canEdit;
  final bool canBlock;
  final bool canUnblock;
  final bool canRevoke;

  bool get isActive => status.toLowerCase() == 'active';
  bool get isBlocked => status.toLowerCase().contains('block');
  bool get isRevoked => status.toLowerCase().contains('revok');

  String get maskedUid {
    final uid = cardUid.trim();
    if (uid.length <= 6) return uid;
    return '${uid.substring(0, 4)}…${uid.substring(uid.length - 4)}';
  }
}
