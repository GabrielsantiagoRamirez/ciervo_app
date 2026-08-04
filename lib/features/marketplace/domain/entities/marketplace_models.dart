class MarketplacePromo {
  const MarketplacePromo({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.title,
    this.description,
    this.promotionType = 'standard',
    this.price,
    this.offerPrice,
    this.currency = 'COP',
    this.stock,
    this.hasDelivery = false,
    this.hasCashback = false,
    this.isHighlighted = false,
    this.city,
    this.dayMode,
    this.categoryId,
    this.subcategoryId,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.startsAt,
    this.endsAt,
    this.marketplaceStatus = 'active',
    this.coverImageUrl,
    this.imageUrls = const [],
    this.videoUrl,
    this.viewsCount = 0,
    this.clicksCount = 0,
    this.favoritesCount = 0,
    this.isFavorite = false,
    this.ctaType,
    this.ctaValue,
    this.cashbackType,
    this.cashbackValue,
    this.cashbackAmount,
    this.pointsEnabled = false,
    this.points = 0,
    this.membershipOnly = false,
    this.premiumOnly = false,
    this.reservationEnabled = false,
    this.pickupEnabled = false,
    this.conditions,
    this.discountPercent,
    this.paymentMethods = const [],
  });

  final int id;
  final int businessId;
  final String businessName;
  final String title;
  final String? description;
  final String promotionType;
  final double? price;
  final double? offerPrice;
  final String currency;
  final int? stock;
  final bool hasDelivery;
  final bool hasCashback;
  final bool isHighlighted;
  final String? city;
  final String? dayMode;
  final int? categoryId;
  final int? subcategoryId;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String marketplaceStatus;
  final String? coverImageUrl;
  final List<String> imageUrls;
  final String? videoUrl;
  final int viewsCount;
  final int clicksCount;
  final int favoritesCount;
  final bool isFavorite;
  final String? ctaType;
  final String? ctaValue;
  final String? cashbackType;
  final double? cashbackValue;
  final double? cashbackAmount;
  final bool pointsEnabled;
  final int points;
  final bool membershipOnly;
  final bool premiumOnly;
  final bool reservationEnabled;
  final bool pickupEnabled;
  final String? conditions;
  final double? discountPercent;
  final List<String> paymentMethods;

  String get imageUrl => (coverImageUrl?.isNotEmpty == true)
      ? coverImageUrl!
      : (imageUrls.isNotEmpty ? imageUrls.first : '');

  MarketplacePromo copyWith({bool? isFavorite}) => MarketplacePromo(
    id: id,
    businessId: businessId,
    businessName: businessName,
    title: title,
    description: description,
    promotionType: promotionType,
    price: price,
    offerPrice: offerPrice,
    currency: currency,
    stock: stock,
    hasDelivery: hasDelivery,
    hasCashback: hasCashback,
    isHighlighted: isHighlighted,
    city: city,
    dayMode: dayMode,
    categoryId: categoryId,
    subcategoryId: subcategoryId,
    latitude: latitude,
    longitude: longitude,
    distanceKm: distanceKm,
    startsAt: startsAt,
    endsAt: endsAt,
    marketplaceStatus: marketplaceStatus,
    coverImageUrl: coverImageUrl,
    imageUrls: imageUrls,
    videoUrl: videoUrl,
    viewsCount: viewsCount,
    clicksCount: clicksCount,
    favoritesCount: favoritesCount,
    isFavorite: isFavorite ?? this.isFavorite,
    ctaType: ctaType,
    ctaValue: ctaValue,
    cashbackType: cashbackType,
    cashbackValue: cashbackValue,
    cashbackAmount: cashbackAmount,
    pointsEnabled: pointsEnabled,
    points: points,
    membershipOnly: membershipOnly,
    premiumOnly: premiumOnly,
    reservationEnabled: reservationEnabled,
    pickupEnabled: pickupEnabled,
    conditions: conditions,
    discountPercent: discountPercent,
    paymentMethods: paymentMethods,
  );
}

class MarketplaceFeedPage {
  const MarketplaceFeedPage({
    required this.items,
    this.total = 0,
    this.page = 1,
    this.limit = 20,
  });

  final List<MarketplacePromo> items;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;
}

class MarketplaceFilterOption {
  const MarketplaceFilterOption({
    required this.id,
    required this.name,
    this.icon,
    this.subcategories = const [],
  });

  final int id;
  final String name;
  final String? icon;
  final List<MarketplaceFilterOption> subcategories;
}

class MarketplaceFiltersCatalog {
  const MarketplaceFiltersCatalog({
    this.categories = const [],
    this.cities = const [],
    this.dayModes = const ['day', 'night', '24h'],
    this.priceMin,
    this.priceMax,
  });

  final List<MarketplaceFilterOption> categories;
  final List<String> cities;
  final List<String> dayModes;
  final double? priceMin;
  final double? priceMax;
}

class MarketplaceFeedQuery {
  const MarketplaceFeedQuery({
    this.page = 1,
    this.limit = 20,
    this.categoria,
    this.categoryId,
    this.subcategoria,
    this.subcategoryId,
    this.ciudad,
    this.dia,
    this.noche,
    this.horas24,
    this.delivery,
    this.cashback,
    this.onlyCashback,
    this.onlyPoints,
    this.precioMin,
    this.precioMax,
    this.buscar,
    this.order,
    this.businessId,
  });

  final int page;
  final int limit;
  final String? categoria;
  final int? categoryId;
  final String? subcategoria;
  final int? subcategoryId;
  final String? ciudad;
  final bool? dia;
  final bool? noche;
  final bool? horas24;
  final bool? delivery;
  final bool? cashback;
  final bool? onlyCashback;
  final bool? onlyPoints;
  final double? precioMin;
  final double? precioMax;
  final String? buscar;
  final String? order;
  final String? businessId;

  int get activeCount {
    var n = 0;
    if (categoryId != null || (categoria?.isNotEmpty ?? false)) n++;
    if (subcategoryId != null || (subcategoria?.isNotEmpty ?? false)) n++;
    if (ciudad?.isNotEmpty ?? false) n++;
    if (dia == true || noche == true || horas24 == true) n++;
    if (delivery == true) n++;
    if (cashback == true || onlyCashback == true) n++;
    if (onlyPoints == true) n++;
    if (precioMin != null || precioMax != null) n++;
    if (order?.isNotEmpty ?? false) n++;
    return n;
  }

  Map<String, dynamic> toQueryParameters() => {
    'page': page,
    'limit': limit,
    if (categoria != null && categoria!.isNotEmpty) 'categoria': categoria,
    if (categoryId != null) 'categoryId': categoryId,
    if (subcategoria != null && subcategoria!.isNotEmpty)
      'subcategoria': subcategoria,
    if (subcategoryId != null) 'subcategoryId': subcategoryId,
    if (ciudad != null && ciudad!.isNotEmpty) 'ciudad': ciudad,
    if (dia == true) 'dia': true,
    if (noche == true) 'noche': true,
    if (horas24 == true) 'horas24': true,
    if (delivery == true) 'delivery': true,
    if (cashback == true) 'cashback': true,
    if (onlyCashback == true) 'onlyCashback': true,
    if (onlyPoints == true) 'onlyPoints': true,
    if (precioMin != null) 'precioMin': precioMin,
    if (precioMax != null) 'precioMax': precioMax,
    if (buscar != null && buscar!.isNotEmpty) 'buscar': buscar,
    if (order != null && order!.isNotEmpty) 'order': order,
    if (businessId != null && businessId!.isNotEmpty) 'businessId': businessId,
  };

  MarketplaceFeedQuery copyWith({
    int? page,
    int? limit,
    String? categoria,
    int? categoryId,
    String? subcategoria,
    int? subcategoryId,
    String? ciudad,
    bool? dia,
    bool? noche,
    bool? horas24,
    bool? delivery,
    bool? cashback,
    bool? onlyCashback,
    bool? onlyPoints,
    double? precioMin,
    double? precioMax,
    String? buscar,
    String? order,
    String? businessId,
    bool clearCategory = false,
    bool clearCity = false,
    bool clearDayModes = false,
    bool clearPrice = false,
    bool clearSearch = false,
    bool clearDelivery = false,
    bool clearCashback = false,
    bool clearOnlyPoints = false,
    bool clearOrder = false,
  }) => MarketplaceFeedQuery(
    page: page ?? this.page,
    limit: limit ?? this.limit,
    categoria: clearCategory ? null : (categoria ?? this.categoria),
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    subcategoria: clearCategory ? null : (subcategoria ?? this.subcategoria),
    subcategoryId: clearCategory ? null : (subcategoryId ?? this.subcategoryId),
    ciudad: clearCity ? null : (ciudad ?? this.ciudad),
    dia: clearDayModes ? dia : (dia ?? this.dia),
    noche: clearDayModes ? noche : (noche ?? this.noche),
    horas24: clearDayModes ? horas24 : (horas24 ?? this.horas24),
    delivery: clearDelivery ? null : (delivery ?? this.delivery),
    cashback: clearCashback ? null : (cashback ?? this.cashback),
    onlyCashback: clearCashback ? null : (onlyCashback ?? this.onlyCashback),
    onlyPoints: clearOnlyPoints ? null : (onlyPoints ?? this.onlyPoints),
    precioMin: clearPrice ? null : (precioMin ?? this.precioMin),
    precioMax: clearPrice ? null : (precioMax ?? this.precioMax),
    buscar: clearSearch ? null : (buscar ?? this.buscar),
    order: clearOrder ? null : (order ?? this.order),
    businessId: businessId ?? this.businessId,
  );

  MarketplaceFeedQuery cleared() => const MarketplaceFeedQuery();
}

class MarketplaceStore {
  const MarketplaceStore({
    required this.storeId,
    required this.name,
    this.ciervoId = '',
    this.description,
    this.category,
    this.coverImage,
    this.logo,
    this.rating,
    this.followers = 0,
    this.distance,
    this.distanceKm,
    this.open = false,
    this.delivery = false,
    this.ciervoPay = false,
    this.cashbackEnabled = false,
    this.pointsEnabled = false,
    this.city,
    this.address,
    this.schedule,
    this.phones = const [],
    this.acceptedPaymentMethods = const [],
    this.gallery = const [],
    this.activePromotions = 0,
    this.promotions = const [],
  });

  final int storeId;
  final String ciervoId;
  final String name;
  final String? description;
  final String? category;
  final String? coverImage;
  final String? logo;
  final double? rating;
  final int followers;
  final String? distance;
  final double? distanceKm;
  final bool open;
  final bool delivery;
  final bool ciervoPay;
  final bool cashbackEnabled;
  final bool pointsEnabled;
  final String? city;
  final String? address;
  final String? schedule;
  final List<String> phones;
  final List<String> acceptedPaymentMethods;
  final List<String> gallery;
  final int activePromotions;
  final List<MarketplacePromo> promotions;
}

class MarketplaceBenefits {
  const MarketplaceBenefits({
    required this.subtotal,
    required this.discount,
    required this.cashback,
    required this.points,
    required this.membershipBonus,
    required this.totalPoints,
    required this.totalPay,
    this.currency = 'COP',
    this.conditions,
    this.membershipOnly = false,
    this.premiumOnly = false,
    this.eligible = true,
    this.eligibilityMessage,
  });

  final double subtotal;
  final double discount;
  final double cashback;
  final int points;
  final int membershipBonus;
  final int totalPoints;
  final double totalPay;
  final String currency;
  final String? conditions;
  final bool membershipOnly;
  final bool premiumOnly;
  final bool eligible;
  final String? eligibilityMessage;
}

class MarketplaceOrder {
  const MarketplaceOrder({
    required this.id,
    required this.promotionId,
    required this.promotionTitle,
    required this.businessId,
    required this.businessName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.currency = 'COP',
    this.paymentMethod = 'CONTACT',
    this.status = 'pending',
    this.notes,
    this.createdAt,
    this.cancelledAt,
    this.cashbackAwarded = 0,
    this.pointsAwarded = 0,
    this.transactionCode,
  });

  final int id;
  final int promotionId;
  final String promotionTitle;
  final int businessId;
  final String businessName;
  final int quantity;
  final double unitPrice;
  final double total;
  final String currency;
  final String paymentMethod;
  final String status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? cancelledAt;
  final double cashbackAwarded;
  final int pointsAwarded;
  final String? transactionCode;
}

class MarketplaceReservation {
  const MarketplaceReservation({
    required this.id,
    required this.promotionId,
    required this.promotionTitle,
    required this.businessId,
    required this.businessName,
    required this.reservedAt,
    this.people = 1,
    this.comments,
    this.status = 'pending',
    this.createdAt,
  });

  final int id;
  final int promotionId;
  final String promotionTitle;
  final int businessId;
  final String businessName;
  final DateTime reservedAt;
  final int people;
  final String? comments;
  final String status;
  final DateTime? createdAt;
}
