class PaymentHistoryItem {
  const PaymentHistoryItem({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    this.createdAt,
    this.receiptUrl,
  });

  final String id;
  final String type;
  final String status;
  final double amount;
  final String currency;
  final String? createdAt;
  final String? receiptUrl;

  String get statusLabel => switch (status.toLowerCase()) {
        'pending' => 'Pendiente',
        'processing' => 'Procesando',
        'approved' || 'succeeded' => 'Aprobado',
        'rejected' || 'failed' => 'Rechazado',
        'cancelled' => 'Cancelado',
        'expired' => 'Expirado',
        _ => status,
      };
}
