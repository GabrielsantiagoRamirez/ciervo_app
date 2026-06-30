import '../../domain/entities/business_summary.dart';

class BusinessSummaryDto {
  const BusinessSummaryDto({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.distanceKm,
    required this.imageUrl,
    this.businessCategoryId,
    required this.priceLevel,
    required this.isFavorite,
    required this.isPartner,
    required this.hasCashback,
    this.benefitTier,
  });

  factory BusinessSummaryDto.fromJson(Map<String, dynamic> json) {
    return BusinessSummaryDto(
      id: _string(json, const ['businessId', 'BusinessId', 'id']),
      name: _string(json, const [
        'name',
        'businessName',
        'title',
        'nombre',
        'Nombre',
      ]),
      category: _string(json, const [
        'category',
        'categoryName',
        'type',
        'categoria',
        'Categoria',
      ]),
      rating: _double(json, const ['rating', 'score']),
      distanceKm: _double(json, const ['distanceKm', 'distance', 'kilometers']),
      imageUrl: _mediaUrl(json),
      businessCategoryId: _intOrNull(
        json['businessCategoryId'] ??
            json['categoryId'] ??
            json['CategoryId'] ??
            json['businessCategory']?['id'],
      ),
      priceLevel: _string(json, const ['priceLevel', 'priceRange']),
      isFavorite: _bool(json, const ['isFavorite', 'favorite']),
      isPartner: _bool(json, const ['isPartner', 'isAllied', 'allied']),
      hasCashback: _bool(json, const ['hasCashback', 'cashbackAvailable']),
      benefitTier: _stringOrNull(json, const [
        'benefitTier',
        'membershipTier',
        'requiredPlan',
        'planCode',
      ]),
    );
  }

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

  BusinessSummary toDomain() {
    return BusinessSummary(
      id: id,
      name: name,
      category: category,
      rating: rating,
      distanceKm: distanceKm,
      imageUrl: imageUrl,
      businessCategoryId: businessCategoryId,
      priceLevel: priceLevel,
      isFavorite: isFavorite,
      isPartner: isPartner,
      hasCashback: hasCashback,
      benefitTier: benefitTier,
    );
  }

  static List<BusinessSummaryDto> listFromResponse(dynamic response) {
    final source = response is Map<String, dynamic>
        ? response['value'] ?? response['data'] ?? response
        : response;
    final items = source is List
        ? source
        : source is Map<String, dynamic> && source['items'] is List
        ? source['items'] as List
        : const [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(BusinessSummaryDto.fromJson)
        .toList();
  }

  static String _string(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  static double _double(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.toDouble();
      }
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) {
        return parsed;
      }
    }
    return 0;
  }

  static int? _intOrNull(dynamic value) {
    if (value is int) return value;
    return int.tryParse('${value ?? ''}');
  }

  static bool _bool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value != null) return value.toString().toLowerCase() == 'true';
    }
    return false;
  }

  static String? _stringOrNull(Map<String, dynamic> json, List<String> keys) {
    final value = _string(json, keys);
    return value.isEmpty ? null : value;
  }

  static String _mediaUrl(Map<String, dynamic> json) {
    final direct = _string(json, const [
      'imageMediaId', 'coverMediaId', 'logoMediaId', 'eventImageMediaId',
      'promotionImageMediaId', 'mediaId',
    ]);
    if (direct.isNotEmpty) return direct;
    for (final key in const ['cover', 'logo', 'image', 'eventImage', 'promotionImage']) {
      final media = json[key];
      if (media is Map) {
        final id = _string(Map<String, dynamic>.from(media), const ['id', 'mediaId']);
        if (id.isNotEmpty) return id;
      }
    }
    final gallery = json['gallery'] ??
        json['galleryImages'] ??
        json['imagenes'] ??
        json['Imagenes'];
    if (gallery is List && gallery.isNotEmpty) {
      final first = gallery.first;
      if (first is String) return first;
      if (first is Map) {
        return _string(Map<String, dynamic>.from(first), const ['id', 'mediaId']);
      }
    }
    return '';
  }
}
