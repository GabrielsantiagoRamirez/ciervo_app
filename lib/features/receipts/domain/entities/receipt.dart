class Receipt {
  const Receipt({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.date,
    required this.status,
    this.description,
    this.userCiervoCode,
    this.publicReceiptUrl,
    this.shareTitle,
    this.shareDescription,
  });

  final String id;
  final String title;
  final double amount;
  final String currency;
  final DateTime? date;
  final String status;
  final String? description;
  final String? userCiervoCode;
  final String? publicReceiptUrl;
  final String? shareTitle;
  final String? shareDescription;
}
