import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/ciervo_share.dart';
import '../../../../core/utils/display_labels.dart';
import '../../../../shared/widgets/ciervo_payment_receipt.dart';
import '../../../receipts/domain/entities/action_confirmation.dart';
import '../../../receipts/presentation/pages/receipts_page.dart';
import '../../domain/entities/financial_history_item.dart';
import '../utils/receipt_share_text.dart';

void openFinancialMovementDetail(BuildContext context, FinancialHistoryItem item) {
  if (item.hasReceipt) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReceiptDetailPage(id: '${item.receiptId}'),
      ),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FinancialMovementDetailPage(item: item),
    ),
  );
}

class FinancialMovementDetailPage extends StatelessWidget {
  const FinancialMovementDetailPage({required this.item, super.key});

  final FinancialHistoryItem item;

  Future<void> _share(BuildContext context) async {
    await CiervoShare.shareText(
      ReceiptShareText.fromMovement(item),
      subject: 'Comprobante CIERVO',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Detalle del movimiento'),
          actions: [
            IconButton(
              tooltip: 'Compartir comprobante',
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: () => _share(context),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            CiervoPaymentReceipt(
              confirmation: ActionConfirmation(
                title: item.displayTitle,
                confirmationCode: '${item.sourceId}',
                amount: item.amount,
                currency: item.currency,
                status: DisplayLabels.receiptStatus(item.status),
                date: item.date?.toIso8601String(),
                shareDescription: '¡Gracias por confiar en CIERVO!',
              ),
              referenceLabel: 'Tipo',
              referenceValue: item.type,
            ),
            if (item.balanceBefore != null && item.balanceAfter != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Saldo anterior: ${item.currency} ${item.balanceBefore!.toStringAsFixed(0)}',
              ),
              Text(
                'Saldo nuevo: ${item.currency} ${item.balanceAfter!.toStringAsFixed(0)}',
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => _share(context),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Compartir comprobante'),
            ),
          ],
        ),
      );
}
