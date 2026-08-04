/// Etiquetas UI para estados y rechazos NFC (contrato §8).
abstract final class NfcPaymentUi {
  static String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'quoted':
        return 'Resumen listo';
      case 'pendingnfctap':
        return 'Acerca tu celular';
      case 'pendingparentapproval':
        return 'Esperando al tutor';
      case 'approved':
        return 'Pago aprobado';
      case 'rejected':
        return 'Pago rechazado';
      case 'cancelled':
        return 'Pago cancelado';
      case 'expired':
        return 'Pago expirado';
      case 'failed':
        return 'No se pudo completar';
      default:
        return status;
    }
  }

  static String rejectReasonMessage(String? reason) {
    switch (reason?.toLowerCase()) {
      case 'insufficientfunds':
        return 'Saldo insuficiente. Recarga tu wallet.';
      case 'paymentmethodinvalid':
        return 'Método de pago no válido.';
      case 'mercadopagorejected':
        return 'Mercado Pago rechazó el pago.';
      case 'cardrejected':
        return 'Tu tarjeta fue rechazada.';
      case 'parentrejected':
        return 'El tutor rechazó el pago.';
      case 'limitexceeded':
        return 'Superaste el límite permitido.';
      case 'kidsruleblocked':
        return 'Bloqueado por reglas parentales.';
      case 'nfcnotavailable':
        return 'NFC no disponible en tu plan.';
      case 'expired':
        return 'El pago expiró. Intenta de nuevo.';
      default:
        return 'Error inesperado. Intenta nuevamente.';
    }
  }

  static String formatMoney(double amount, String currency) {
    // Reutiliza el formateador global: CLP 20.000
    // ignore: avoid_relative_lib_imports
    return _formatWithThousands(amount, currency);
  }

  static String _formatWithThousands(double amount, String currency) {
    final value = amount.round();
    final sign = value < 0 ? '-' : '';
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    final code = currency.trim().toUpperCase();
    return '$code $sign$buffer';
  }
}
