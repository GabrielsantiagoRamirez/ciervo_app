class RechargeIntent {
  const RechargeIntent({
    required this.id,
    this.preferenceId = '',
    required this.checkoutUrl,
    required this.status,
  });

  final String id;
  final String preferenceId;
  final String checkoutUrl;
  final String status;

  bool isCheckoutHostAllowedFor(String countryCode) {
    final uri = Uri.tryParse(checkoutUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return false;
    final expected = switch (countryCode.trim().toUpperCase()) {
      'CL' => 'mercadopago.cl',
      'CO' => 'mercadopago.com.co',
      _ => '',
    };
    if (expected.isEmpty) return false;
    final host = uri.host.toLowerCase();
    return host == expected || host.endsWith('.$expected');
  }

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
