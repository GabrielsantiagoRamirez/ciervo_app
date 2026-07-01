class WalletCard {
  const WalletCard({
    required this.id,
    required this.name,
    required this.balance,
    required this.heldBalance,
    required this.availableBalance,
    required this.currency,
    required this.status,
    required this.isPrimary,
    this.mask,
    this.isBlocked = false,
  });

  final String id;
  final String name;
  final double balance;
  final double heldBalance;
  final double availableBalance;
  final String currency;
  final String status;
  final bool isPrimary;
  final String? mask;
  final bool isBlocked;

  bool get isInactive =>
      status.toLowerCase().contains('inactive') ||
      status.toLowerCase().contains('delete');

  bool canSpend(double amount) => !isBlocked && !isInactive && availableBalance >= amount;
}
