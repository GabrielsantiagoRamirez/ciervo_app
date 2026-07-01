class FamilyPaymentCard {
  const FamilyPaymentCard({
    required this.id,
    required this.brand,
    required this.lastFour,
    required this.status,
    required this.isPrimary,
    required this.isBackup,
    required this.expirationMonth,
    required this.expirationYear,
    required this.alias,
    this.isFrozen = false,
  });

  final String id;
  final String brand;
  final String lastFour;
  final String status;
  final bool isPrimary;
  final bool isBackup;
  final String expirationMonth;
  final String expirationYear;
  final String alias;
  final bool isFrozen;

  String get expirationLabel {
    if (expirationMonth.isEmpty && expirationYear.isEmpty) return '—';
    final month = expirationMonth.padLeft(2, '0');
    final year = expirationYear.length >= 2
        ? expirationYear.substring(expirationYear.length - 2)
        : expirationYear;
    return '$month/$year';
  }

  String get maskedNumber => '**** $lastFour';

  bool get isActive =>
      !isFrozen &&
      !status.toLowerCase().contains('inactive') &&
      !status.toLowerCase().contains('removed');
}
