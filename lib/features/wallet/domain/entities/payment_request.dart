class PaymentRequest {
  const PaymentRequest({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.description,
    this.rawStatus = '',
    this.payerName,
    this.targetName,
    this.requesterName,
    this.requesterUsername,
    this.requesterCiervoId,
    this.payerUsername,
    this.payerCiervoId,
    this.createdAt,
    this.expiresAt,
  });

  final String id;
  final double amount;
  final String currency;
  final String status;
  final String rawStatus;
  final String description;
  final String? payerName;
  final String? targetName;
  final String? requesterName;
  final String? requesterUsername;
  final String? requesterCiervoId;
  final String? payerUsername;
  final String? payerCiervoId;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  bool get isPending {
    final normalized = rawStatus.isNotEmpty
        ? rawStatus.toLowerCase()
        : status.toLowerCase();
    return normalized.contains('pending') ||
        normalized.contains('pendiente') ||
        normalized == '1' ||
        normalized == 'open' ||
        normalized == 'requested' ||
        status == 'Pendiente';
  }
}
