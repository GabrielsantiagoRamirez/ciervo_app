import '../../domain/entities/paid_campaign.dart';

class PaidCampaignDto {
  const PaidCampaignDto({
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

  factory PaidCampaignDto.fromJson(Map<String, dynamic> json) => PaidCampaignDto(
        id: _string(json, const ['id', 'campaignId', 'adsCampaignId']),
        title: _string(json, const ['title', 'name', 'headline']),
        description: _string(json, const ['description', 'body', 'message']),
        imageUrl: _media(json),
        status: _string(json, const ['status', 'campaignStatus'], fallback: 'ACTIVE'),
        businessId: _nullable(json['businessId'] ?? json['business']?['id']),
        businessName: _nullable(
          json['businessName'] ?? json['business']?['name'],
        ),
        bonusId: _nullable(json['bonusId'] ?? json['linkedBonusId']),
        promotionId: _nullable(json['promotionId']),
        deepLink: _nullable(json['deepLink'] ?? json['targetUrl']),
        city: _nullable(json['city']),
        zone: _nullable(json['zone']),
        country: _nullable(json['country'] ?? json['countryCode']),
        distanceKm: _doubleOrNull(json['distanceKm']),
        publishedAt: DateTime.tryParse(
          '${json['publishedAt'] ?? json['createdAt'] ?? ''}',
        ),
      );

  PaidCampaign toEntity() => PaidCampaign(
        id: id,
        title: title,
        description: description,
        imageUrl: imageUrl,
        status: status,
        businessId: businessId,
        businessName: businessName,
        bonusId: bonusId,
        promotionId: promotionId,
        deepLink: deepLink,
        city: city,
        zone: zone,
        country: country,
        distanceKm: distanceKm,
        publishedAt: publishedAt,
      );

  static List<PaidCampaignDto> listFromResponse(dynamic response) {
    final items = _unwrapList(response);
    return items.map(PaidCampaignDto.fromJson).toList();
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

String _string(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }
  return fallback;
}

String? _nullable(dynamic value) =>
    value == null || value.toString().isEmpty ? null : value.toString();

double? _doubleOrNull(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}');
}

String _media(Map<String, dynamic> json) {
  final direct = _nullable(
    json['imageUrl'] ??
        json['bannerUrl'] ??
        json['imageMediaId'] ??
        json['coverMediaId'] ??
        json['mediaId'],
  );
  if (direct != null) return direct;
  final image = json['image'] ?? json['banner'];
  if (image is Map) {
    return _nullable(image['id'] ?? image['mediaId'] ?? image['url']) ?? '';
  }
  return '';
}
