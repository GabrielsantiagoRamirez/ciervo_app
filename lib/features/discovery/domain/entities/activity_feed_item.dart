class ActivityFeedItem {
  const ActivityFeedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.category,
    this.businessId,
    this.eventId,
    this.productId,
    this.promotionId,
    this.giftCardId,
    this.benefitId,
    this.rewardId,
    this.couponId,
    this.deepLink,
    this.imageMediaId,
    this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String description;
  final String? category;
  final int? businessId;
  final int? eventId;
  final int? productId;
  final int? promotionId;
  final int? giftCardId;
  final int? benefitId;
  final int? rewardId;
  final int? couponId;
  final String? deepLink;
  final String? imageMediaId;
  final DateTime? createdAt;
}
