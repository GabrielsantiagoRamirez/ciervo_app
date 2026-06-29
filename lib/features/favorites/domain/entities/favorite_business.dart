class FavoriteBusiness {
  const FavoriteBusiness({
    required this.businessId,
    required this.name,
    required this.category,
    required this.rating,
    required this.distanceKm,
    required this.logoUrl,
    required this.coverUrl,
    required this.activeBonusesCount,
    required this.activeCampaignsCount,
    required this.isFavorite,
    this.country,
    this.city,
    this.zone,
    this.favoriteAt,
    this.businessCategoryId,
    this.priceLevel = '',
  });

  final String businessId;
  final String name;
  final String category;
  final String? country;
  final String? city;
  final String? zone;
  final String logoUrl;
  final String coverUrl;
  final double rating;
  final double distanceKm;
  final DateTime? favoriteAt;
  final int activeBonusesCount;
  final int activeCampaignsCount;
  final bool isFavorite;
  final int? businessCategoryId;
  final String priceLevel;

  String get id => businessId;

  String get imageUrl => coverUrl.isNotEmpty ? coverUrl : logoUrl;
}
