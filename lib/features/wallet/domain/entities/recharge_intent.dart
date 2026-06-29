class RechargeIntent {
  const RechargeIntent({
    required this.id,
    required this.checkoutUrl,
    required this.status,
  });

  final String id;
  final String checkoutUrl;
  final String status;

  bool get isSucceeded {
    final normalized = status.toLowerCase();
    return normalized == 'approved' ||
        normalized == '4' ||
        normalized == 'succeeded' ||
        normalized.contains('success') ||
        normalized.contains('paid');
  }

  bool get isRejected {
    final normalized = status.toLowerCase();
    return normalized == 'rejected' ||
        normalized == 'failed' ||
        normalized == '5';
  }

  bool get isTerminal =>
      isSucceeded ||
      isRejected ||
      status.toLowerCase() == 'cancelled' ||
      status.toLowerCase() == 'expired' ||
      status == '6' ||
      status == '7';

  String get statusLabel {
    return switch (status.toLowerCase()) {
      'pending' || '1' => 'Pendiente',
      'processing' || '2' => 'Procesando',
      'approved' || '4' || 'succeeded' => 'Aprobado',
      'rejected' || 'failed' || '5' => 'Rechazado',
      'cancelled' || '6' => 'Cancelado',
      'expired' || '7' => 'Expirado',
      '3' || 'requiresexternalaction' => 'Esperando pago externo',
      _ => status,
    };
  }
}
