class ActivityFeedItem {
  const ActivityFeedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.category,
    this.businessId,
    this.businessName,
    this.eventId,
    this.productId,
    this.promotionId,
    this.giftCardId,
    this.benefitId,
    this.rewardId,
    this.couponId,
    this.bonusId,
    this.campaignId,
    this.deepLink,
    this.imageMediaId,
    this.imageUrl,
    this.createdAt,
    this.price,
    this.currency = 'COP',
    this.cashbackAmount,
    this.cashbackPercent,
    this.cashbackLabel,
    this.points,
    this.hasCashback = false,
    this.hasPoints = false,
    this.isFavoriteBusiness = false,
  });

  final String id;
  final String type;
  final String title;
  final String description;
  final String? category;
  final int? businessId;
  final String? businessName;
  final int? eventId;
  final int? productId;
  final int? promotionId;
  final int? giftCardId;
  final int? benefitId;
  final int? rewardId;
  final int? couponId;
  final String? bonusId;
  final String? campaignId;
  final String? deepLink;
  final String? imageMediaId;

  /// URL pública CDN (`coverImageUrl` / `productImageUrl`). Preferir sobre mediaId.
  final String? imageUrl;
  final DateTime? createdAt;
  final double? price;
  final String currency;
  final double? cashbackAmount;
  final double? cashbackPercent;
  final String? cashbackLabel;
  final int? points;
  final bool hasCashback;
  final bool hasPoints;
  final bool isFavoriteBusiness;

  bool get showsCashback =>
      hasCashback ||
      (cashbackAmount != null && cashbackAmount! > 0) ||
      (cashbackPercent != null && cashbackPercent! > 0) ||
      (cashbackLabel?.isNotEmpty ?? false);

  bool get showsPoints => hasPoints || (points != null && points! > 0);

  String? get cashbackDisplay {
    if (cashbackLabel != null && cashbackLabel!.trim().isNotEmpty) {
      return cashbackLabel!.trim();
    }
    if (cashbackPercent != null && cashbackPercent! > 0) {
      return '${cashbackPercent!.toStringAsFixed(cashbackPercent! % 1 == 0 ? 0 : 1)}% cashback';
    }
    if (cashbackAmount != null && cashbackAmount! > 0) {
      return 'Cashback';
    }
    if (hasCashback) return 'Cashback';
    return null;
  }

  String? get pointsDisplay {
    if (points != null && points! > 0) return '$points pts';
    if (hasPoints) return 'Puntos';
    return null;
  }

  /// Imagen a mostrar: URL CDN primero; si no, mediaId autenticado.
  String? get displayImageRef {
    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) return url;
    final media = imageMediaId?.trim();
    if (media != null && media.isNotEmpty) return media;
    return null;
  }

  bool get hasNetworkImage {
    final url = imageUrl?.trim() ?? '';
    return url.startsWith('http://') || url.startsWith('https://');
  }

  ActivityFeedItem copyWith({bool? isFavoriteBusiness}) => ActivityFeedItem(
    id: id,
    type: type,
    title: title,
    description: description,
    category: category,
    businessId: businessId,
    businessName: businessName,
    eventId: eventId,
    productId: productId,
    promotionId: promotionId,
    giftCardId: giftCardId,
    benefitId: benefitId,
    rewardId: rewardId,
    couponId: couponId,
    bonusId: bonusId,
    campaignId: campaignId,
    deepLink: deepLink,
    imageMediaId: imageMediaId,
    imageUrl: imageUrl,
    createdAt: createdAt,
    price: price,
    currency: currency,
    cashbackAmount: cashbackAmount,
    cashbackPercent: cashbackPercent,
    cashbackLabel: cashbackLabel,
    points: points,
    hasCashback: hasCashback,
    hasPoints: hasPoints,
    isFavoriteBusiness: isFavoriteBusiness ?? this.isFavoriteBusiness,
  );
}
