import 'move_enums.dart';

/// Parámetros para estimar / solicitar una tarifa MOVE.
class MoveFareRequest {
  const MoveFareRequest({
    required this.countryCode,
    required this.vehicleCategory,
    required this.distanceKm,
    required this.durationMin,
    this.city,
    this.waitMinutes = 0,
    this.isNight = false,
    this.isRaining = false,
    this.highDemandPct = 0,
    this.isAirport = false,
    this.tolls = 0,
    this.promoAmount = 0,
    this.cashbackToApply = 0,
  });

  final String countryCode;
  final String? city;
  final MoveVehicleCategory vehicleCategory;
  final double distanceKm;
  final int durationMin;
  final int waitMinutes;
  final bool isNight;
  final bool isRaining;
  final int highDemandPct;
  final bool isAirport;
  final int tolls;
  final int promoAmount;
  final int cashbackToApply;

  Map<String, dynamic> toJson() => {
    'countryCode': countryCode,
    'city': city,
    'vehicleCategory': vehicleCategory.value,
    'distanceKm': distanceKm,
    'durationMin': durationMin,
    'waitMinutes': waitMinutes,
    'isNight': isNight,
    'isRaining': isRaining,
    'highDemandPct': highDemandPct,
    'isAirport': isAirport,
    'tolls': tolls,
    'promoAmount': promoAmount,
    'cashbackToApply': cashbackToApply,
  };
}

/// Renglón del desglose de tarifa (banda o recargo).
class MoveFareBreakdownItem {
  const MoveFareBreakdownItem({required this.label, required this.amount});

  final String label;
  final int amount;
}

/// Tarifa sugerida y rango negociable devuelto por el backend.
class MoveFareQuote {
  const MoveFareQuote({
    required this.suggestedFare,
    required this.minOffer,
    required this.maxOffer,
    required this.currency,
    this.breakdown = const [],
  });

  final int suggestedFare;
  final int minOffer;
  final int maxOffer;
  final String currency;
  final List<MoveFareBreakdownItem> breakdown;

  bool isWithinRange(int amount) => amount >= minOffer && amount <= maxOffer;

  int clampToRange(int amount) {
    if (amount < minOffer) return minOffer;
    if (amount > maxOffer) return maxOffer;
    return amount;
  }
}
