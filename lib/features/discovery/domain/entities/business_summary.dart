class BusinessSummary {
  const BusinessSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.distanceKm,
    required this.imageUrl,
    this.businessCategoryId,
    this.priceLevel = '',
    this.isFavorite = false,
    this.isPartner = false,
    this.hasCashback = false,
    this.benefitTier,
    this.experienceBucket,
    this.open24Hours = false,
    this.acceptsCiervoPayments = false,
    this.hasDelivery = false,
    this.requiresReservation = false,
    this.isFamilyFriendly = false,
    this.isPetFriendly = false,
    this.isAccessible = false,
    this.hasParking = false,
    this.hasActivePromotions = false,
    this.isOpen,
  });

  final String id;
  final String name;
  final String category;
  final double rating;
  final double distanceKm;
  final String imageUrl;
  final int? businessCategoryId;
  final String priceLevel;
  final bool isFavorite;
  final bool isPartner;
  final bool hasCashback;
  final String? benefitTier;
  final String? experienceBucket;
  final bool open24Hours;
  final bool acceptsCiervoPayments;
  final bool hasDelivery;
  final bool requiresReservation;
  final bool isFamilyFriendly;
  final bool isPetFriendly;
  final bool isAccessible;
  final bool hasParking;
  final bool hasActivePromotions;

  /// null = desconocido (no inventar estado)
  final bool? isOpen;

  List<BusinessAmenity> get activeAmenities {
    return [
      if (acceptsCiervoPayments) BusinessAmenity.ciervo,
      if (hasDelivery) BusinessAmenity.delivery,
      if (requiresReservation) BusinessAmenity.reservation,
      if (isFamilyFriendly) BusinessAmenity.family,
      if (isPetFriendly) BusinessAmenity.pet,
      if (isAccessible) BusinessAmenity.accessible,
      if (hasParking) BusinessAmenity.parking,
      if (open24Hours) BusinessAmenity.open24h,
    ];
  }
}

enum BusinessAmenity {
  ciervo,
  delivery,
  reservation,
  family,
  pet,
  accessible,
  parking,
  open24h,
}
