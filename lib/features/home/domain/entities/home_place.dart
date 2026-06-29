class HomePlace {
  const HomePlace({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.priceLevel,
    required this.distanceKm,
    required this.matchPercent,
    required this.imageUrl,
    this.businessCategoryId,
    this.isFavorite = false,
    this.isPartner = false,
    this.hasCashback = false,
    this.benefitTier,
    this.city,
    this.countryCode,
  });

  final String id;
  final String name;
  final String category;
  final double rating;
  final String priceLevel;
  final double distanceKm;
  final int matchPercent;
  final String imageUrl;
  final int? businessCategoryId;
  final bool isFavorite;
  final bool isPartner;
  final bool hasCashback;
  final String? benefitTier;
  final String? city;
  final String? countryCode;
}
