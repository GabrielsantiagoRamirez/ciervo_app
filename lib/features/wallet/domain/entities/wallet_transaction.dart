class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.direction,
    required this.amount,
    required this.currency,
    required this.description,
    required this.createdAt,
    this.balanceBefore,
    this.balanceAfter,
  });

  final String id;
  final String type;
  final String direction;
  final double amount;
  final String currency;
  final String description;
  final DateTime? createdAt;
  final double? balanceBefore;
  final double? balanceAfter;
}
