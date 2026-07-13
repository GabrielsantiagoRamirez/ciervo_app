class SavedPaymentMethod {
  const SavedPaymentMethod({
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

  bool get isActive => status.toLowerCase() == 'active';

  String get label {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    if (last4 != null && last4!.isNotEmpty) {
      return '$brand ·••• $last4';
    }
    return brand.isNotEmpty ? brand : type;
  }
}

class UniversalNfcPayment {
  const UniversalNfcPayment({
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

  bool get isPendingParentApproval =>
      status.toLowerCase() == 'pendingparentapproval';

  bool get isPendingNfcTap => status.toLowerCase() == 'pendingnfctap';

  bool get isApproved => status.toLowerCase() == 'approved' || approved == true;

  bool get isRejected => status.toLowerCase() == 'rejected';

  bool get isCancelled => status.toLowerCase() == 'cancelled';

  bool get isExpired => status.toLowerCase() == 'expired';

  bool get isFailed => status.toLowerCase() == 'failed';

  String get qrToken {
    final payload = nfcPayload;
    if (payload == null) return '';
    final token = payload['t'] ?? payload['token'];
    return token?.toString() ?? '';
  }
}

class KidsNfcParentApproval {
  const KidsNfcParentApproval({
    required this.paymentIntentId,
    required this.kidId,
    required this.kidName,
    required this.amount,
    required this.currency,
    required this.merchantName,
    this.requestedAt,
    this.approvalId,
  });

  final String paymentIntentId;
  final String kidId;
  final String kidName;
  final double amount;
  final String currency;
  final String merchantName;
  final DateTime? requestedAt;
  final String? approvalId;
}
