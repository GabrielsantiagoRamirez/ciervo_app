class QrResolveResult {
  const QrResolveResult({
    required this.channel,
    this.token,
    this.code,
    this.qrPayload,
    this.recommendedEndpoint,
    this.description,
  });

  final String channel;
  final String? token;
  final String? code;
  final String? qrPayload;
  final String? recommendedEndpoint;
  final String? description;

  bool get isPayment => channel == 'payment';
  bool get isCiervoUser => channel == 'ciervo_user';
  bool get isUniversal => channel == 'universal';
  bool get isBookingCode => channel == 'booking_code';
  bool get isTicketCode => channel == 'ticket_code';
  bool get isGiftCardCode => channel == 'gift_card_code';
  bool get isUnknown => channel == 'unknown';
}

class QrPaymentDetails {
  const QrPaymentDetails({
    required this.token,
    required this.businessId,
    required this.businessName,
    required this.amount,
    required this.currency,
    required this.status,
    required this.isExpired,
    this.description,
    this.paymentIntentId,
    this.expiresAt,
  });

  final String token;
  final int businessId;
  final String businessName;
  final double amount;
  final String currency;
  final String status;
  final bool isExpired;
  final String? description;
  final int? paymentIntentId;
  final DateTime? expiresAt;

  bool get canPay => !isExpired && status.toLowerCase() == 'pending';
}

class QrPaymentResult {
  const QrPaymentResult({
    required this.status,
    required this.paymentMethod,
    this.paymentIntentId,
    this.checkoutUrl,
    this.receiptNumber,
    this.receiptId,
    this.amount,
    this.currency,
  });

  final String status;
  final String paymentMethod;
  final int? paymentIntentId;
  final String? checkoutUrl;
  final String? receiptNumber;
  final String? receiptId;
  final double? amount;
  final String? currency;

  String? get receiptLookupId =>
      (receiptId != null && receiptId!.isNotEmpty)
          ? receiptId
          : receiptNumber;
}

class QrValidatePreview {
  const QrValidatePreview({
    required this.valid,
    required this.type,
    required this.canRedeem,
    required this.requiresConfirmation,
    this.qrId,
    this.title,
    this.ownerName,
    this.message,
    this.businessId,
    this.ownerId,
    this.token,
    this.recommendedRedeemEndpoint,
    this.benefitTitle,
    this.benefitDescription,
    this.couponTitle,
    this.couponDescription,
  });

  final bool valid;
  final String type;
  final bool canRedeem;
  final bool requiresConfirmation;
  final int? qrId;
  final String? title;
  final String? ownerName;
  final String? message;
  final int? businessId;
  final int? ownerId;
  final String? token;
  final String? recommendedRedeemEndpoint;
  final String? benefitTitle;
  final String? benefitDescription;
  final String? couponTitle;
  final String? couponDescription;

  bool get isCoupon => type.toLowerCase().contains('coupon');
  bool get isBenefit => type.toLowerCase().contains('benefit');
}
