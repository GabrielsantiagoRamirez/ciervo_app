import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/action_confirmation.dart';
import '../../../../shared/widgets/ciervo_payment_receipt.dart';
import '../../../../shared/widgets/ciervo_user_id_badge.dart';

class ActionConfirmationPage extends StatelessWidget {
  const ActionConfirmationPage({
    required this.confirmation,
    super.key,
    this.referenceLabel,
    this.referenceValue,
    this.onDone,
  });

  final ActionConfirmation confirmation;
  final String? referenceLabel;
  final String? referenceValue;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recibo de pago'),
        actions: [
          TextButton(
            onPressed: () {
              if (onDone != null) {
                onDone!();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Listo'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          CiervoPaymentReceipt(
            confirmation: confirmation,
            referenceLabel: referenceLabel,
            referenceValue: referenceValue,
          ),
          if (confirmation.publicReceiptUrl != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir recibo en línea'),
              onPressed: () =>
                  launchUrl(Uri.parse(confirmation.publicReceiptUrl!)),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () {
              if (onDone != null) {
                onDone!();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}

Future<void> showCiervoPaymentReceipt(
  BuildContext context, {
  required ActionConfirmation confirmation,
  String? referenceLabel,
  String? referenceValue,
  VoidCallback? onDone,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => ActionConfirmationPage(
        confirmation: confirmation,
        referenceLabel: referenceLabel,
        referenceValue: referenceValue,
        onDone: onDone,
      ),
    ),
  );
}

Future<String?> resolveCurrentCiervoUserCode() =>
    resolveCiervoUserCodeForSession();
