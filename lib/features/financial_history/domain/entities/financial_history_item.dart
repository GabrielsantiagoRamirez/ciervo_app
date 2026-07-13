class FinancialHistoryItem {
  const FinancialHistoryItem({
    required this.id,
    required this.source,
    required this.sourceId,
    required this.type,
    required this.direction,
    required this.amount,
    required this.currency,
    required this.status,
    required this.date,
    required this.description,
    this.receiptId,
    this.paymentIntentId,
    this.referenceType,
    this.referenceId,
    this.balanceBefore,
    this.balanceAfter,
  });

  final String id;
  final String source;
  final int sourceId;
  final String type;
  final String direction;
  final double amount;
  final String currency;
  final String status;
  final DateTime? date;
  final String description;
  final int? receiptId;
  final int? paymentIntentId;
  final String? referenceType;
  final String? referenceId;
  final double? balanceBefore;
  final double? balanceAfter;

  bool get isCredit =>
      direction.toLowerCase().contains('credit') ||
      direction.toLowerCase().contains('in');

  String get displayTitle => description.isNotEmpty ? description : type;

  bool get hasReceipt => receiptId != null && receiptId! > 0;
}
