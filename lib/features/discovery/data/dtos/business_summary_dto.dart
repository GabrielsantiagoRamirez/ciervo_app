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
    this.experienceBucket,
    required this.open24Hours,
    required this.acceptsCiervoPayments,
    required this.hasDelivery,
    required this.requiresReservation,
    required this.isFamilyFriendly,
    required this.isPetFriendly,
    required this.isAccessible,
    required this.hasParking,
    required this.hasActivePromotions,
    this.isOpen,
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
      experienceBucket: _stringOrNull(json, const [
        'experienceBucket',
        'bucket',
      ]),
      open24Hours: _bool(json, const ['open24Hours', 'isOpen24Hours']),
      acceptsCiervoPayments: _bool(json, const [
        'acceptsCiervoPayments',
        'acceptsCiervo',
      ]),
      hasDelivery: _bool(json, const ['hasDelivery', 'delivery']),
      requiresReservation: _bool(json, const [
        'requiresReservation',
        'reservationRequired',
      ]),
      isFamilyFriendly: _bool(json, const [
        'isFamilyFriendly',
        'familyFriendly',
      ]),
      isPetFriendly: _bool(json, const ['isPetFriendly', 'petFriendly']),
      isAccessible: _bool(json, const ['isAccessible', 'accessible']),
      hasParking: _bool(json, const ['hasParking', 'parking']),
      hasActivePromotions:
          _bool(json, const [
            'hasActivePromotions',
            'hasPromotions',
            'tienePromociones',
          ]) ||
          _hasPromoList(json),
      isOpen: _openState(json),
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
  final bool? isOpen;

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
      experienceBucket: experienceBucket,
      open24Hours: open24Hours,
      acceptsCiervoPayments: acceptsCiervoPayments,
      hasDelivery: hasDelivery,
      requiresReservation: requiresReservation,
      isFamilyFriendly: isFamilyFriendly,
      isPetFriendly: isPetFriendly,
      isAccessible: isAccessible,
      hasParking: hasParking,
      hasActivePromotions: hasActivePromotions,
      isOpen: isOpen,
    );
  }

  static List<BusinessSummaryDto> listFromResponse(dynamic response) {
    final source = response is Map
        ? (response['value'] ??
              response['data'] ??
              response['Value'] ??
              response['Data'] ??
              response)
        : response;
    List? rawItems;
    if (source is List) {
      rawItems = source;
    } else if (source is Map) {
      final nested = source['items'] ?? source['Items'];
      if (nested is List) rawItems = nested;
    }
    rawItems ??= const [];

    return rawItems
        .whereType<Map>()
        .map((item) => BusinessSummaryDto.fromJson(
              Map<String, dynamic>.from(item),
            ))
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

  static bool _hasPromoList(Map<String, dynamic> json) {
    final promos =
        json['promocionesActivas'] ??
        json['activePromotions'] ??
        json['promotions'];
    return promos is List && promos.isNotEmpty;
  }

  static bool? _openState(Map<String, dynamic> json) {
    if (json.containsKey('isOpen') || json.containsKey('openNow')) {
      final value = json['isOpen'] ?? json['openNow'];
      if (value is bool) return value;
      if (value != null) return value.toString().toLowerCase() == 'true';
    }
    final estado = (json['estado'] ?? json['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (estado.isEmpty) return null;
    if (estado.contains('abierto') || estado == 'open') return true;
    if (estado.contains('cerrado') || estado == 'closed') return false;
    return null;
  }

  static String _mediaUrl(Map<String, dynamic> json) {
    final direct = _string(json, const [
      'imageMediaId',
      'coverMediaId',
      'logoMediaId',
      'eventImageMediaId',
      'promotionImageMediaId',
      'mediaId',
    ]);
    if (direct.isNotEmpty) return direct;
    for (final key in const [
      'cover',
      'logo',
      'image',
      'eventImage',
      'promotionImage',
    ]) {
      final media = json[key];
      if (media is Map) {
        final id = _string(Map<String, dynamic>.from(media), const [
          'id',
          'mediaId',
        ]);
        if (id.isNotEmpty) return id;
      }
    }
    final gallery =
        json['gallery'] ??
        json['galleryImages'] ??
        json['imagenes'] ??
        json['Imagenes'];
    if (gallery is List && gallery.isNotEmpty) {
      final first = gallery.first;
      if (first is String) return first;
      if (first is Map) {
        return _string(Map<String, dynamic>.from(first), const [
          'id',
          'mediaId',
        ]);
      }
    }
    return '';
  }
}
