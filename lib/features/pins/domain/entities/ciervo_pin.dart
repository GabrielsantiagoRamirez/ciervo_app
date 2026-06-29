class CiervoPin {
  const CiervoPin({
    required this.id,
    required this.amount,
    required this.status,
    required this.statusName,
    this.pin,
    this.currency = 'COP',
    this.expiresAt,
    this.walletHoldId,
    this.businessId,
  });

  final String id;
  final String? pin;
  final double amount;
  final String currency;
  final String status;
  final String statusName;
  final DateTime? expiresAt;
  final String? walletHoldId;
  final String? businessId;

  bool get isActive {
    final code = int.tryParse(status);
    if (code != null) return code >= 1 && code <= 4;
    final normalized = statusName.toLowerCase();
    return normalized.contains('held') ||
        normalized.contains('created') ||
        normalized.contains('waiting') ||
        normalized.contains('approved');
  }

  bool get canCancel => isActive;

  String get displayStatus {
    if (statusName.isNotEmpty) return statusName;
    return switch (status) {
      '1' => 'Creado',
      '2' => 'Fondos retenidos',
      '3' => 'Esperando pago',
      '4' => 'Pago aprobado',
      '5' => 'Completado',
      '6' => 'Cancelado',
      '7' => 'Expirado',
      '8' => 'Rechazado',
      '9' => 'Fraude detectado',
      _ => status,
    };
  }
}
