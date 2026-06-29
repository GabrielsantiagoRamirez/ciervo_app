class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.priceUsd,
    required this.baseCurrency,
    this.estimatedLocalPrice,
    this.estimatedLocalCurrency,
    this.billingCurrency,
    this.countryCode,
    this.paymentProvider,
    required this.benefits,
    required this.limits,
    required this.supportsCheckout,
    required this.requiresCustomQuote,
    required this.audience,
    required this.cashbackMultiplier,
    required this.isCurrent,
    this.status,
    this.expiresAt,
    this.sortOrder = 0,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final double priceUsd;
  final String baseCurrency;
  final double? estimatedLocalPrice;
  final String? estimatedLocalCurrency;
  final String? billingCurrency;
  final String? countryCode;
  final String? paymentProvider;
  final List<String> benefits;
  final Map<String, String> limits;
  final bool supportsCheckout;
  final bool requiresCustomQuote;
  final String audience;
  final double cashbackMultiplier;
  final bool isCurrent;
  final String? status;
  final DateTime? expiresAt;
  final int sortOrder;

  bool get isFree => priceUsd <= 0 || code.toUpperCase() == 'FREE';

  String get displayPrice {
    if (isFree) return 'Gratis';
    if (estimatedLocalPrice != null && estimatedLocalCurrency != null) {
      return '$estimatedLocalCurrency ${estimatedLocalPrice!.toStringAsFixed(0)} / mes';
    }
    return '$baseCurrency ${priceUsd.toStringAsFixed(2)} / mes';
  }

  String get displayUsdReference {
    if (isFree) return '';
    return '$baseCurrency ${priceUsd.toStringAsFixed(2)}';
  }
}
