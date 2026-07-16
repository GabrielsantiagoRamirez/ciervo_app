/// Filtros smart de discovery (query params del API).
class DiscoverySmartFilters {
  const DiscoverySmartFilters({
    this.radiusKm = defaultRadiusKm,
    this.minRating,
    this.openNow = false,
    this.acceptsCiervoPayments = false,
    this.hasDelivery = false,
    this.requiresReservation = false,
    this.hasPromotions = false,
    this.familyFriendly = false,
    this.petFriendly = false,
    this.accessible = false,
    this.hasParking = false,
  });

  static const double defaultRadiusKm = 25;
  static const double expandedRadiusKm = 50;

  final double radiusKm;
  final double? minRating;
  final bool openNow;
  final bool acceptsCiervoPayments;
  final bool hasDelivery;
  final bool requiresReservation;
  final bool hasPromotions;
  final bool familyFriendly;
  final bool petFriendly;
  final bool accessible;
  final bool hasParking;

  bool get hasActiveFilters =>
      radiusKm != defaultRadiusKm ||
      minRating != null ||
      openNow ||
      acceptsCiervoPayments ||
      hasDelivery ||
      requiresReservation ||
      hasPromotions ||
      familyFriendly ||
      petFriendly ||
      accessible ||
      hasParking;

  int get activeCount {
    var count = 0;
    if (radiusKm != defaultRadiusKm) count++;
    if (minRating != null) count++;
    if (openNow) count++;
    if (acceptsCiervoPayments) count++;
    if (hasDelivery) count++;
    if (requiresReservation) count++;
    if (hasPromotions) count++;
    if (familyFriendly) count++;
    if (petFriendly) count++;
    if (accessible) count++;
    if (hasParking) count++;
    return count;
  }

  Map<String, dynamic> toQueryParameters({bool includeRadius = true}) {
    return {
      if (includeRadius) 'radiusKm': radiusKm,
      if (minRating != null) 'minRating': minRating,
      if (openNow) 'openNow': true,
      if (acceptsCiervoPayments) 'acceptsCiervoPayments': true,
      if (hasDelivery) 'hasDelivery': true,
      if (requiresReservation) 'requiresReservation': true,
      if (hasPromotions) 'hasPromotions': true,
      if (familyFriendly) 'familyFriendly': true,
      if (petFriendly) 'petFriendly': true,
      if (accessible) 'accessible': true,
      if (hasParking) 'hasParking': true,
    };
  }

  DiscoverySmartFilters copyWith({
    double? radiusKm,
    double? minRating,
    bool clearMinRating = false,
    bool? openNow,
    bool? acceptsCiervoPayments,
    bool? hasDelivery,
    bool? requiresReservation,
    bool? hasPromotions,
    bool? familyFriendly,
    bool? petFriendly,
    bool? accessible,
    bool? hasParking,
  }) {
    return DiscoverySmartFilters(
      radiusKm: radiusKm ?? this.radiusKm,
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      openNow: openNow ?? this.openNow,
      acceptsCiervoPayments:
          acceptsCiervoPayments ?? this.acceptsCiervoPayments,
      hasDelivery: hasDelivery ?? this.hasDelivery,
      requiresReservation: requiresReservation ?? this.requiresReservation,
      hasPromotions: hasPromotions ?? this.hasPromotions,
      familyFriendly: familyFriendly ?? this.familyFriendly,
      petFriendly: petFriendly ?? this.petFriendly,
      accessible: accessible ?? this.accessible,
      hasParking: hasParking ?? this.hasParking,
    );
  }

  DiscoverySmartFilters cleared() => const DiscoverySmartFilters();

  DiscoverySmartFilters withExpandedRadius() =>
      copyWith(radiusKm: expandedRadiusKm);
}
