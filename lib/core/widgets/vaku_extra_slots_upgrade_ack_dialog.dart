import 'package:flutter/material.dart';

import '../../features/vakupli/data/vakupli_repository.dart';
import '../di/service_locator.dart';

/// Modal obligatorio antes de mejorar membresía si hay cupos extra Vaku activos.
///
/// Retorna `true` si el usuario confirma continuar el upgrade,
/// `false` si cancela o si no hace falta acknowledge.
Future<bool> acknowledgeVakuExtraSlotsBeforeUpgrade(
  BuildContext context,
) async {
  final result = await getIt<VakupliRepository>().myExtraSlots();
  if (!context.mounted) return false;

  return result.when(
    success: (status) async {
      if (!status.acknowledgeBeforePlanUpgrade) return true;
      final modal = status.upgradeModal;
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(modal.title),
            content: SingleChildScrollView(
              child: Text(modal.body),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(modal.cancelLabel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(modal.continueUpgradeLabel),
              ),
            ],
          ),
        ),
      );
      return confirmed == true;
    },
    failure: (_) async {
      // Si falla la consulta, no bloqueamos el upgrade de membresía.
      return true;
    },
  );
}
