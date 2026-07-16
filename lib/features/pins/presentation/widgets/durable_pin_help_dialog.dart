import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/durable_pin_service.dart';

/// Explicación del PIN semanal (primera vez o bajo demanda).
Future<void> showDurablePinHelpDialog(
  BuildContext context, {
  bool markSeen = false,
}) async {
  if (markSeen) {
    await getIt<DurablePinService>().markHelpSeen();
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Tu PIN Ciervo'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Este es tu PIN semanal para pagar en comercios afiliados o a '
              'otra persona dentro de Ciervo.',
            ),
            SizedBox(height: AppSpacing.md),
            Text('• No lo compartas con nadie en quien no confíes.'),
            SizedBox(height: AppSpacing.sm),
            Text(
              '• No reemplaza tu código Ciervo ni sirve para iniciar '
              'transferencias normales por ID.',
            ),
            SizedBox(height: AppSpacing.sm),
            Text('• Rota cada semana automáticamente.'),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

Future<void> maybeShowDurablePinHelpOnFirstView(BuildContext context) async {
  final service = getIt<DurablePinService>();
  if (await service.hasSeenHelp()) return;
  if (!context.mounted) return;
  await showDurablePinHelpDialog(context, markSeen: true);
}
