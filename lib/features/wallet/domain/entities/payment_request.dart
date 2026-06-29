class PaymentRequest {
  const PaymentRequest({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.description,
    this.payerName,
    this.targetName,
    this.createdAt,
    this.expiresAt,
  });

  final String id;
  final double amount;
  final String currency;
  final String status;
  final String description;
  final String? payerName;
  final String? targetName;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  bool get isPending {
    final normalized = status.toLowerCase();
    return normalized.contains('pending') ||
        normalized.contains('pendiente') ||
        normalized == '1' ||
        normalized == 'open' ||
        normalized == 'requested';
  }
}
