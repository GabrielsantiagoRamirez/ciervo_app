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
}
