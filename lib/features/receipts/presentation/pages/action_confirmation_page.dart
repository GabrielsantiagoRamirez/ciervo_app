import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/action_confirmation.dart';

class ActionConfirmationPage extends StatelessWidget {
  const ActionConfirmationPage({required this.confirmation, super.key});

  final ActionConfirmation confirmation;

  @override
  Widget build(BuildContext context) {
    final amount = confirmation.amount == null
        ? null
        : '${confirmation.currency ?? 'COP'} ${confirmation.amount!.toStringAsFixed(0)}';
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmacion')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: AppRadii.card,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.verified, color: AppColors.primary, size: 56),
                const SizedBox(height: AppSpacing.md),
                Text(
                  confirmation.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _row('Codigo', confirmation.confirmationCode),
                if (confirmation.businessName != null)
                  _row('Negocio', confirmation.businessName!),
                if (amount != null) _row('Valor', amount),
                if (confirmation.status != null)
                  _row('Estado', confirmation.status!),
                if (confirmation.date != null) _row('Fecha', confirmation.date!),
                if (confirmation.time != null) _row('Hora', confirmation.time!),
                if (confirmation.userCiervoCode != null)
                  _codeRow('Ciervo ID', confirmation.userCiervoCode!),
                if (confirmation.shareDescription != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    confirmation.shareDescription!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
          if (confirmation.publicReceiptUrl != null) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir recibo'),
              onPressed: () => launchUrl(Uri.parse(confirmation.publicReceiptUrl!)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white70)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Widget _codeRow(String label, String value) => Container(
    margin: const EdgeInsets.only(top: AppSpacing.xs),
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      borderRadius: AppRadii.input,
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
    ),
    child: _row(label, value),
  );
}
