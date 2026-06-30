import '../../../../core/utils/display_labels.dart';

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
    this.period,
    this.isRecommended = false,
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
  final String? period;
  final bool isRecommended;

  bool get isFree => priceUsd <= 0 || code.toUpperCase() == 'FREE';

  String get displayPeriodLabel {
    if (period == null || period!.isEmpty) return '/ mes';
    return ' / ${DisplayLabels.planPeriod(period)}';
  }

  String get displayPrice {
    final suffix = displayPeriodLabel;
    if (isFree) return 'Gratis';
    if (estimatedLocalPrice != null && estimatedLocalCurrency != null) {
      return '$estimatedLocalCurrency ${estimatedLocalPrice!.toStringAsFixed(0)}$suffix';
    }
    return '$baseCurrency ${priceUsd.toStringAsFixed(2)}$suffix';
  }

  String get displayUsdReference {
    if (isFree) return '';
    return '$baseCurrency ${priceUsd.toStringAsFixed(2)}';
  }
}
