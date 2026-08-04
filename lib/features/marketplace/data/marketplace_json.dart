import '../domain/entities/marketplace_models.dart';

class MarketplaceJson {
  const MarketplaceJson._();

  static MarketplacePromo promoFromJson(Map<String, dynamic> json) {
    final images = <String>[];
    final rawImages = json['imageUrls'] ?? json['images'];
    if (rawImages is List) {
      for (final item in rawImages) {
        final value = item?.toString();
        if (value != null && value.isNotEmpty) images.add(value);
      }
    }

    final methods = <String>[];
    final rawMethods = json['paymentMethods'];
    if (rawMethods is List) {
      for (final item in rawMethods) {
        final value = item?.toString();
        if (value != null && value.isNotEmpty) methods.add(value);
      }
    }

    return MarketplacePromo(
      id: _int(json['id']),
      businessId: _int(json['businessId']),
      businessName: _str(json['businessName']),
      title: _str(json['title']),
      description: _strOrNull(json['description']),
      promotionType: _str(json['promotionType'], fallback: 'standard'),
      price: _doubleOrNull(json['price']),
      offerPrice: _doubleOrNull(json['offerPrice']),
      currency: _str(json['currency'], fallback: 'COP'),
      stock: _intOrNull(json['stock']),
      hasDelivery: _bool(json['hasDelivery']),
      hasCashback: _bool(json['hasCashback']),
      isHighlighted: _bool(json['isHighlighted']),
      city: _strOrNull(json['city']),
      dayMode: _strOrNull(json['dayMode']),
      categoryId: _intOrNull(json['categoryId']),
      subcategoryId: _intOrNull(json['subcategoryId']),
      latitude: _doubleOrNull(json['latitude']),
      longitude: _doubleOrNull(json['longitude']),
      distanceKm: _doubleOrNull(json['distanceKm']),
      startsAt: _date(json['startsAt']),
      endsAt: _date(json['endsAt']),
      marketplaceStatus: _str(json['marketplaceStatus'], fallback: 'active'),
      coverImageUrl: _strOrNull(json['coverImageUrl'] ?? json['coverImage']),
      imageUrls: images,
      videoUrl: _strOrNull(json['videoUrl']),
      viewsCount: _int(json['viewsCount']),
      clicksCount: _int(json['clicksCount']),
      favoritesCount: _int(json['favoritesCount']),
      isFavorite: _bool(json['isFavorite']),
      ctaType: _strOrNull(json['ctaType']),
      ctaValue: _strOrNull(json['ctaValue']),
      cashbackType: _strOrNull(json['cashbackType']),
      cashbackValue: _doubleOrNull(json['cashbackValue']),
      cashbackAmount: _doubleOrNull(json['cashbackAmount']),
      pointsEnabled: _bool(json['pointsEnabled']),
      points: _int(json['points']),
      membershipOnly: _bool(json['membershipOnly']),
      premiumOnly: _bool(json['premiumOnly']),
      reservationEnabled: _bool(json['reservationEnabled']),
      pickupEnabled: _bool(json['pickupEnabled']),
      conditions: _strOrNull(json['conditions']),
      discountPercent: _doubleOrNull(json['discountPercent']),
      paymentMethods: methods,
    );
  }

  static MarketplaceFeedPage feedFromJson(dynamic value) {
    if (value is List) {
      final items = value
          .whereType<Map>()
          .map((e) => promoFromJson(Map<String, dynamic>.from(e)))
          .toList();
      return MarketplaceFeedPage(items: items, total: items.length);
    }
    final map = _asMap(value);
    final rawItems = map['items'] ?? map['Items'] ?? const [];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((e) => promoFromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <MarketplacePromo>[];
    return MarketplaceFeedPage(
      items: items,
      total: _int(map['total'], fallback: items.length),
      page: _int(map['page'], fallback: 1),
      limit: _int(map['limit'], fallback: 20),
    );
  }

  static List<MarketplacePromo> promoListFromJson(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => promoFromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return feedFromJson(value).items;
  }

  static MarketplaceFiltersCatalog filtersFromJson(dynamic value) {
    final map = _asMap(value);
    final categories = <MarketplaceFilterOption>[];
    final rawCats = map['categories'];
    if (rawCats is List) {
      for (final item in rawCats.whereType<Map>()) {
        categories.add(_filterOption(Map<String, dynamic>.from(item)));
      }
    }
    final cities = <String>[];
    final rawCities = map['cities'];
    if (rawCities is List) {
      for (final city in rawCities) {
        final text = city?.toString();
        if (text != null && text.isNotEmpty) cities.add(text);
      }
    }
    final dayModes = <String>[];
    final rawModes = map['dayModes'];
    if (rawModes is List) {
      for (final mode in rawModes) {
        final text = mode?.toString();
        if (text != null && text.isNotEmpty) dayModes.add(text);
      }
    }
    return MarketplaceFiltersCatalog(
      categories: categories,
      cities: cities,
      dayModes: dayModes.isEmpty ? const ['day', 'night', '24h'] : dayModes,
      priceMin: _doubleOrNull(map['priceMin']),
      priceMax: _doubleOrNull(map['priceMax']),
    );
  }

  static MarketplaceStore storeFromJson(dynamic value) {
    final map = _asMap(value);
    final phones = <String>[];
    final rawPhones = map['phones'];
    if (rawPhones is List) {
      for (final phone in rawPhones) {
        final text = phone?.toString();
        if (text != null && text.isNotEmpty) phones.add(text);
      }
    }
    final payments = <String>[];
    final rawPayments = map['acceptedPaymentMethods'];
    if (rawPayments is List) {
      for (final method in rawPayments) {
        final text = method?.toString();
        if (text != null && text.isNotEmpty) payments.add(text);
      }
    }
    final gallery = <String>[];
    final rawGallery = map['gallery'];
    if (rawGallery is List) {
      for (final item in rawGallery) {
        final text = item?.toString();
        if (text != null && text.isNotEmpty) gallery.add(text);
      }
    }
    final promotions = promoListFromJson(map['promotions']);

    return MarketplaceStore(
      storeId: _int(map['storeId'] ?? map['id'] ?? map['businessId']),
      ciervoId: _str(map['ciervoId']),
      name: _str(map['name'] ?? map['businessName']),
      description: _strOrNull(map['description']),
      category: _strOrNull(map['category']),
      coverImage: _strOrNull(map['coverImage'] ?? map['coverImageUrl']),
      logo: _strOrNull(map['logo']),
      rating: _doubleOrNull(map['rating']),
      followers: _int(map['followers']),
      distance: _strOrNull(map['distance']),
      distanceKm: _doubleOrNull(map['distanceKm']),
      open: _bool(map['open'] ?? map['isOpen']),
      delivery: _bool(map['delivery'] ?? map['hasDelivery']),
      ciervoPay: _bool(map['ciervoPay'] ?? map['acceptsCiervoPayments']),
      cashbackEnabled: _bool(map['cashbackEnabled']),
      pointsEnabled: _bool(map['pointsEnabled']),
      city: _strOrNull(map['city']),
      address: _strOrNull(map['address']),
      schedule: _strOrNull(map['schedule']),
      phones: phones,
      acceptedPaymentMethods: payments,
      gallery: gallery,
      activePromotions: _int(
        map['activePromotions'],
        fallback: promotions.length,
      ),
      promotions: promotions,
    );
  }

  static MarketplaceBenefits benefitsFromJson(dynamic value) {
    final map = _asMap(value);
    return MarketplaceBenefits(
      subtotal: _double(map['subtotal']),
      discount: _double(map['discount']),
      cashback: _double(map['cashback']),
      points: _int(map['points']),
      membershipBonus: _int(map['membershipBonus']),
      totalPoints: _int(map['totalPoints']),
      totalPay: _double(map['totalPay']),
      currency: _str(map['currency'], fallback: 'COP'),
      conditions: _strOrNull(map['conditions']),
      membershipOnly: _bool(map['membershipOnly']),
      premiumOnly: _bool(map['premiumOnly']),
      eligible: map.containsKey('eligible') ? _bool(map['eligible']) : true,
      eligibilityMessage: _strOrNull(map['eligibilityMessage']),
    );
  }

  static MarketplaceOrder orderFromJson(dynamic value) {
    final map = _asMap(value);
    final nested = map['order'];
    final source = nested is Map ? Map<String, dynamic>.from(nested) : map;
    return MarketplaceOrder(
      id: _int(source['id']),
      promotionId: _int(source['promotionId']),
      promotionTitle: _str(source['promotionTitle']),
      businessId: _int(source['businessId']),
      businessName: _str(source['businessName']),
      quantity: _int(source['quantity'], fallback: 1),
      unitPrice: _double(source['unitPrice']),
      total: _double(source['total']),
      currency: _str(source['currency'], fallback: 'COP'),
      paymentMethod: _str(source['paymentMethod'], fallback: 'CONTACT'),
      status: _str(source['status'], fallback: 'pending'),
      notes: _strOrNull(source['notes']),
      createdAt: _date(source['createdAt']),
      cancelledAt: _date(source['cancelledAt']),
      cashbackAwarded: _double(source['cashbackAwarded'] ?? map['cashback']),
      pointsAwarded: _int(source['pointsAwarded'] ?? map['points']),
      transactionCode: _strOrNull(
        source['transactionCode'] ?? map['transaction'],
      ),
    );
  }

  static List<MarketplaceOrder> orderListFromJson(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => orderFromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    final map = _asMap(value);
    final items = map['items'] ?? map['orders'];
    if (items is List) {
      return items
          .whereType<Map>()
          .map((e) => orderFromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  static MarketplaceReservation reservationFromJson(dynamic value) {
    final map = _asMap(value);
    return MarketplaceReservation(
      id: _int(map['id']),
      promotionId: _int(map['promotionId']),
      promotionTitle: _str(map['promotionTitle']),
      businessId: _int(map['businessId']),
      businessName: _str(map['businessName']),
      reservedAt: _date(map['reservedAt']) ?? DateTime.now(),
      people: _int(map['people'], fallback: 1),
      comments: _strOrNull(map['comments']),
      status: _str(map['status'], fallback: 'pending'),
      createdAt: _date(map['createdAt']),
    );
  }

  static MarketplaceFilterOption _filterOption(Map<String, dynamic> json) {
    final subs = <MarketplaceFilterOption>[];
    final raw = json['subcategories'];
    if (raw is List) {
      for (final item in raw.whereType<Map>()) {
        subs.add(_filterOption(Map<String, dynamic>.from(item)));
      }
    }
    return MarketplaceFilterOption(
      id: _int(json['id']),
      name: _str(json['name']),
      icon: _strOrNull(json['icon']),
      subcategories: subs,
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static String _str(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  static String? _strOrNull(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double _double(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double? _doubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1';
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
