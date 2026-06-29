class FinancialHistoryItem {
  const FinancialHistoryItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.date,
    required this.description,
  });

  final String id;
  final String type;
  final double amount;
  final String currency;
  final DateTime? date;
  final String description;
}
