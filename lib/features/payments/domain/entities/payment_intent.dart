class PaymentIntent {
  const PaymentIntent({
    required this.id,
    required this.type,
    required this.status,
    required this.checkoutUrl,
    this.amount,
    this.currency,
    this.membershipPlanId,
    this.receiptUrl,
  });

  final String id;
  final String type;
  final String status;
  final String checkoutUrl;
  final double? amount;
  final String? currency;
  final String? membershipPlanId;
  final String? receiptUrl;

  String get normalizedStatus => status.toLowerCase();

  bool get isApproved =>
      normalizedStatus == 'approved' ||
      normalizedStatus == 'succeeded' ||
      normalizedStatus == '4' ||
      normalizedStatus.contains('success') ||
      normalizedStatus.contains('paid');

  bool get isRejected =>
      normalizedStatus == 'rejected' ||
      normalizedStatus == 'failed' ||
      normalizedStatus == '5';

  bool get isPending =>
      normalizedStatus == 'pending' ||
      normalizedStatus == 'processing' ||
      normalizedStatus == 'requiresexternalaction';

  bool get isTerminal =>
      isApproved || isRejected || normalizedStatus == 'cancelled' || normalizedStatus == 'expired';

  String get statusLabel => switch (normalizedStatus) {
        'pending' => 'Pendiente',
        'processing' => 'Procesando',
        'approved' || 'succeeded' => 'Aprobado',
        'rejected' || 'failed' => 'Rechazado',
        'cancelled' => 'Cancelado',
        'expired' => 'Expirado',
        _ => status,
      };
}
