import 'package:flutter/material.dart';

abstract final class PayForMeLabels {
  static String statusLabel(String? raw) {
    final normalized = (raw ?? '').toLowerCase();
    if (normalized.contains('pending')) return 'Esperando aprobación';
    if (normalized.contains('approved')) return 'Aprobado';
    if (normalized.contains('reject')) return 'Rechazado';
    if (normalized.contains('expir')) return 'Expirado';
    if (normalized.contains('cancel')) return 'Cancelado';
    return raw?.isNotEmpty == true ? raw! : 'Desconocido';
  }

  static Color statusColor(BuildContext context, String? raw) {
    final normalized = (raw ?? '').toLowerCase();
    if (normalized.contains('pending')) {
      return const Color(0xFFE6A817);
    }
    if (normalized.contains('approved')) {
      return const Color(0xFF2E7D52);
    }
    if (normalized.contains('reject')) {
      return Theme.of(context).colorScheme.error;
    }
    if (normalized.contains('expir') || normalized.contains('cancel')) {
      return Theme.of(context).colorScheme.outline;
    }
    return Theme.of(context).colorScheme.primary;
  }
}
