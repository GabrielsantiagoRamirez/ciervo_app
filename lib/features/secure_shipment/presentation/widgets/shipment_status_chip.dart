import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_labels.dart';

class ShipmentStatusChip extends StatelessWidget {
  const ShipmentStatusChip({required this.statusName, super.key});

  final String statusName;

  @override
  Widget build(BuildContext context) {
    final color = DisplayLabels.secureShipmentStatusColor(statusName);
    final label = DisplayLabels.secureShipmentStatus(statusName);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

Future<void> showSecureShipmentPinModal(
  BuildContext context, {
  required String pin,
  String? expiresAt,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Tu PIN de entrega'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Guárdalo ahora. Por seguridad no volveremos a mostrarlo.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SelectableText(
            pin,
            style: Theme.of(ctx).textTheme.displaySmall?.copyWith(
                  letterSpacing: 8,
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ),
          if (expiresAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Válido hasta $expiresAt',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: pin));
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('PIN copiado al portapapeles')),
            );
          },
          child: const Text('Copiar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}
