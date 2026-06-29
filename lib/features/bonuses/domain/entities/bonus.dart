enum BonusStatus {
  draft('DRAFT'),
  pendingPayment('PENDING_PAYMENT'),
  paid('PAID'),
  active('ACTIVE'),
  paused('PAUSED'),
  expired('EXPIRED'),
  soldOut('SOLD_OUT'),
  deleted('DELETED'),
  claimed('CLAIMED'),
  redeemed('REDEEMED');

  const BonusStatus(this.apiValue);

  final String apiValue;

  static BonusStatus? fromApi(String? value) {
    if (value == null || value.isEmpty) return null;
    final normalized = value.toUpperCase();
    for (final status in BonusStatus.values) {
      if (status.apiValue == normalized) return status;
    }
    return null;
  }

  String get label => switch (this) {
        BonusStatus.draft => 'Borrador',
        BonusStatus.pendingPayment => 'Pago pendiente',
        BonusStatus.paid => 'Pagado',
        BonusStatus.active => 'Activo',
        BonusStatus.paused => 'Pausado',
        BonusStatus.expired => 'Vencido',
        BonusStatus.soldOut => 'Agotado',
        BonusStatus.deleted => 'Eliminado',
        BonusStatus.claimed => 'Reclamado',
        BonusStatus.redeemed => 'Usado',
      };

  bool get isUsable =>
      this == BonusStatus.active || this == BonusStatus.claimed;
}

enum BonusType {
  discount('DISCOUNT'),
  cashback('CASHBACK'),
  twoForOne('TWO_FOR_ONE'),
  freeEntry('FREE_ENTRY'),
  gift('GIFT'),
  coupon('COUPON'),
  promoCode('PROMO_CODE');

  const BonusType(this.apiValue);

  final String apiValue;

  static BonusType? fromApi(String? value) {
    if (value == null || value.isEmpty) return null;
    final normalized = value.toUpperCase();
    for (final type in BonusType.values) {
      if (type.apiValue == normalized) return type;
    }
    return null;
  }

  String get label => switch (this) {
        BonusType.discount => 'Descuento',
        BonusType.cashback => 'Cashback',
        BonusType.twoForOne => '2x1',
        BonusType.freeEntry => 'Entrada gratis',
        BonusType.gift => 'Regalo',
        BonusType.coupon => 'Cupon',
        BonusType.promoCode => 'Codigo promo',
      };
}

class Bonus {
  const Bonus({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.businessId,
    required this.businessName,
    required this.currency,
    this.discountPercent,
    this.discountAmount,
    this.cashbackAmount,
    this.savingsAmount,
    this.imageUrl,
    this.validFrom,
    this.validUntil,
    this.claimedAt,
    this.redeemedAt,
    this.promoCode,
    this.paymentMethod,
    this.city,
    this.zone,
    this.country,
    this.distanceKm,
    this.canRedeem = false,
    this.userClaimId,
  });

  final String id;
  final String title;
  final String description;
  final BonusType type;
  final BonusStatus status;
  final String businessId;
  final String businessName;
  final String currency;
  final double? discountPercent;
  final double? discountAmount;
  final double? cashbackAmount;
  final double? savingsAmount;
  final String? imageUrl;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime? claimedAt;
  final DateTime? redeemedAt;
  final String? promoCode;
  final String? paymentMethod;
  final String? city;
  final String? zone;
  final String? country;
  final double? distanceKm;
  final bool canRedeem;
  final String? userClaimId;

  String get benefitLabel {
    if (discountPercent != null && discountPercent! > 0) {
      return '${discountPercent!.toStringAsFixed(0)}% OFF';
    }
    if (discountAmount != null && discountAmount! > 0) {
      return '-$currency ${discountAmount!.toStringAsFixed(0)}';
    }
    if (cashbackAmount != null && cashbackAmount! > 0) {
      return 'Cashback $currency ${cashbackAmount!.toStringAsFixed(0)}';
    }
    if (savingsAmount != null && savingsAmount! > 0) {
      return 'Ahorro $currency ${savingsAmount!.toStringAsFixed(0)}';
    }
    return type.label;
  }
}

class BonusFilters {
  const BonusFilters({
    this.country,
    this.city,
    this.zone,
    this.categoryId,
    this.businessId,
    this.paymentMethod,
    this.nearLat,
    this.nearLng,
    this.radiusKm,
    this.onlyFavorites = false,
    this.activeOnly = true,
    this.page = 1,
    this.pageSize = 30,
  });

  final String? country;
  final String? city;
  final String? zone;
  final int? categoryId;
  final String? businessId;
  final String? paymentMethod;
  final double? nearLat;
  final double? nearLng;
  final double? radiusKm;
  final bool onlyFavorites;
  final bool activeOnly;
  final int page;
  final int pageSize;

  Map<String, dynamic> toQueryParameters() => {
        if (country != null && country!.isNotEmpty) 'country': country,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (zone != null && zone!.isNotEmpty) 'zone': zone,
        if (categoryId != null) 'categoryId': categoryId,
        if (businessId != null && businessId!.isNotEmpty) 'businessId': businessId,
        if (paymentMethod != null && paymentMethod!.isNotEmpty)
          'paymentMethod': paymentMethod,
        if (nearLat != null) 'nearLat': nearLat,
        if (nearLng != null) 'nearLng': nearLng,
        if (radiusKm != null) 'radiusKm': radiusKm,
        if (onlyFavorites) 'onlyFavorites': true,
        if (activeOnly) 'activeOnly': true,
        'page': page,
        'pageSize': pageSize,
      };

  BonusFilters copyWith({
    String? country,
    String? city,
    String? zone,
    int? categoryId,
    String? businessId,
    String? paymentMethod,
    double? nearLat,
    double? nearLng,
    double? radiusKm,
    bool? onlyFavorites,
    bool? activeOnly,
    int? page,
    int? pageSize,
  }) =>
      BonusFilters(
        country: country ?? this.country,
        city: city ?? this.city,
        zone: zone ?? this.zone,
        categoryId: categoryId ?? this.categoryId,
        businessId: businessId ?? this.businessId,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        nearLat: nearLat ?? this.nearLat,
        nearLng: nearLng ?? this.nearLng,
        radiusKm: radiusKm ?? this.radiusKm,
        onlyFavorites: onlyFavorites ?? this.onlyFavorites,
        activeOnly: activeOnly ?? this.activeOnly,
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
      );
}
