import '../../domain/entities/favorite_business.dart';

class FavoriteBusinessDto {
  const FavoriteBusinessDto({
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
    this.priceLevel,
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
  final String? priceLevel;

  factory FavoriteBusinessDto.fromJson(Map<String, dynamic> json) {
    final business = json['business'] is Map
        ? Map<String, dynamic>.from(json['business'] as Map)
        : json;
    return FavoriteBusinessDto(
      businessId: _string(business, const ['businessId', 'id']),
      name: _string(business, const ['name', 'businessName', 'title']),
      category: _string(business, const ['category', 'categoryName', 'type']),
      country: _nullable(business['country'] ?? business['countryCode']),
      city: _nullable(business['city'] ?? business['cityName']),
      zone: _nullable(business['zone'] ?? business['zoneName']),
      logoUrl: _media(business, const ['logoUrl', 'logoMediaId', 'logo']),
      coverUrl: _media(business, const ['coverUrl', 'coverMediaId', 'cover']),
      rating: _double(business, const ['rating', 'score']),
      distanceKm: _double(business, const ['distanceKm', 'distance']),
      favoriteAt: DateTime.tryParse(
        '${json['favoriteAt'] ?? json['createdAt'] ?? json['addedAt'] ?? ''}',
      ),
      activeBonusesCount: _int(
        business['activeBonusesCount'] ?? business['bonusesCount'],
      ),
      activeCampaignsCount: _int(
        business['activeCampaignsCount'] ?? business['campaignsCount'],
      ),
      isFavorite: business['isFavorite'] == true || json['isFavorite'] == true,
      businessCategoryId: _intOrNull(
        business['categoryId'] ??
            business['businessCategoryId'] ??
            business['businessCategory']?['id'],
      ),
      priceLevel: _nullable(business['priceLevel'] ?? business['priceRange']),
    );
  }

  FavoriteBusiness toEntity() => FavoriteBusiness(
        businessId: businessId,
        name: name,
        category: category,
        country: country,
        city: city,
        zone: zone,
        logoUrl: logoUrl,
        coverUrl: coverUrl,
        rating: rating,
        distanceKm: distanceKm,
        favoriteAt: favoriteAt,
        activeBonusesCount: activeBonusesCount,
        activeCampaignsCount: activeCampaignsCount,
        isFavorite: isFavorite,
        businessCategoryId: businessCategoryId,
        priceLevel: priceLevel ?? '',
      );

  static List<FavoriteBusinessDto> listFromResponse(dynamic response) {
    final items = _unwrapList(response);
    return items.map(FavoriteBusinessDto.fromJson).toList();
  }
}

List<Map<String, dynamic>> _unwrapList(dynamic response) {
  dynamic source = response;
  if (source is Map<String, dynamic> && source.containsKey('data')) {
    source = source['data'];
  }
  final items = source is List
      ? source
      : source is Map<String, dynamic> && source['items'] is List
          ? source['items'] as List
          : const [];
  return items
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

String _string(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }
  return '';
}

String? _nullable(dynamic value) =>
    value == null || value.toString().isEmpty ? null : value.toString();

double _double(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse('${value ?? ''}');
    if (parsed != null) return parsed;
  }
  return 0;
}

int _int(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;

int? _intOrNull(dynamic value) => value is int ? value : int.tryParse('$value');

String _media(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map) {
      final id = _string(Map<String, dynamic>.from(value), const ['id', 'mediaId', 'url']);
      if (id.isNotEmpty) return id;
    } else if (value != null && value.toString().isNotEmpty) {
      return value.toString();
    }
  }
  return '';
}
