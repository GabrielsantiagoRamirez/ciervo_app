class DeliveryPricing {
  const DeliveryPricing({
    this.distanceKm,
    this.deliveryFee,
    this.deliveryFeeBase,
    this.platformFee,
    this.courierEarning,
    this.tipAmount,
    this.courierTotal,
    this.baseFee,
    this.includedKm,
    this.extraKm,
    this.additionalKmPrice,
    this.currency,
  });

  final double? distanceKm;
  final num? deliveryFee;
  final num? deliveryFeeBase;
  final num? platformFee;
  final num? courierEarning;
  final num? tipAmount;
  final num? courierTotal;
  final num? baseFee;
  final double? includedKm;
  final double? extraKm;
  final num? additionalKmPrice;
  final String? currency;

  factory DeliveryPricing.fromJson(
    Map<String, dynamic>? json, {
    Map<String, dynamic>? fallback,
  }) {
    num? pick(String key) {
      if (json?[key] != null) return _num(json![key]);
      return fallback == null ? null : _num(fallback[key]);
    }

    double? pickDouble(String key) {
      if (json?[key] != null) return _double(json![key]);
      return fallback == null ? null : _double(fallback[key]);
    }

    String? pickCurrency() {
      final fromPricing = json?['currency'] ?? json?['currencyCode'];
      if (fromPricing != null) return fromPricing.toString();
      final fromFallback = fallback?['currency'] ?? fallback?['currencyCode'];
      return fromFallback?.toString();
    }

    return DeliveryPricing(
      distanceKm: pickDouble('distanceKm') ??
          _double(json?['distance'] ?? fallback?['distance']),
      deliveryFee: pick('deliveryFee') ?? _num(fallback?['deliveryAmount']),
      deliveryFeeBase: pick('deliveryFeeBase'),
      platformFee: pick('platformFee'),
      courierEarning:
          pick('courierEarning') ?? _num(fallback?['estimatedCourierEarning']),
      tipAmount: pick('tipAmount') ?? _num(fallback?['tip']),
      courierTotal: pick('courierTotal'),
      baseFee: pick('baseFee'),
      includedKm: pickDouble('includedKm'),
      extraKm: pickDouble('extraKm'),
      additionalKmPrice: pick('additionalKmPrice'),
      currency: pickCurrency(),
    );
  }

  static double? _double(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value');

  static num? _num(dynamic value) =>
      value is num ? value : num.tryParse('$value');
}
