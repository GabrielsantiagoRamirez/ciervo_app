class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.isRead,
    this.type,
    this.category,
    this.businessId,
    this.eventId,
    this.productId,
    this.serviceId,
    this.promotionId,
    this.discountId,
    this.giftCardId,
    this.benefitId,
    this.rewardId,
    this.couponId,
    this.bookingId,
    this.ticketId,
    this.qrId,
    this.deepLink,
    this.metadataJson,
  });

  final String id;
  final String title;
  final String message;
  final DateTime? date;
  final bool isRead;
  final String? type;
  final String? category;
  final int? businessId;
  final int? eventId;
  final int? productId;
  final int? serviceId;
  final int? promotionId;
  final int? discountId;
  final int? giftCardId;
  final int? benefitId;
  final int? rewardId;
  final int? couponId;
  final int? bookingId;
  final int? ticketId;
  final int? qrId;
  final String? deepLink;
  final String? metadataJson;
}
