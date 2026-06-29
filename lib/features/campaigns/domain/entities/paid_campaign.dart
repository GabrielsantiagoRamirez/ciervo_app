class PaidCampaign {
  const PaidCampaign({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.status,
    this.businessId,
    this.businessName,
    this.bonusId,
    this.promotionId,
    this.deepLink,
    this.city,
    this.zone,
    this.country,
    this.distanceKm,
    this.publishedAt,
  });

  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String status;
  final String? businessId;
  final String? businessName;
  final String? bonusId;
  final String? promotionId;
  final String? deepLink;
  final String? city;
  final String? zone;
  final String? country;
  final double? distanceKm;
  final DateTime? publishedAt;

  bool get isActive =>
      status.isEmpty ||
      status.toUpperCase() == 'ACTIVE' ||
      status.toUpperCase() == 'PUBLISHED' ||
      status.toUpperCase() == 'PAID';
}

class CampaignFilters {
  const CampaignFilters({
    this.country,
    this.city,
    this.zone,
    this.businessId,
    this.nearLat,
    this.nearLng,
    this.radiusKm,
    this.activeOnly = true,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? country;
  final String? city;
  final String? zone;
  final String? businessId;
  final double? nearLat;
  final double? nearLng;
  final double? radiusKm;
  final bool activeOnly;
  final int page;
  final int pageSize;

  Map<String, dynamic> toQueryParameters() => {
        if (country != null && country!.isNotEmpty) 'country': country,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (zone != null && zone!.isNotEmpty) 'zone': zone,
        if (businessId != null && businessId!.isNotEmpty) 'businessId': businessId,
        if (nearLat != null) 'nearLat': nearLat,
        if (nearLng != null) 'nearLng': nearLng,
        if (radiusKm != null) 'radiusKm': radiusKm,
        if (activeOnly) 'activeOnly': true,
        'page': page,
        'pageSize': pageSize,
      };
}
