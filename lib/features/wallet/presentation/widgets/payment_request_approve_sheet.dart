import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../family_payments/domain/entities/family_payment_card.dart';
import '../../../family_payments/domain/repositories/family_payments_repository.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/entities/wallet_card.dart';

class PaymentRequestApproveOptions {
  const PaymentRequestApproveOptions({
    this.useBackupCard = false,
    this.familyPaymentCardId,
  });

  final bool useBackupCard;
  final String? familyPaymentCardId;
}

Future<PaymentRequestApproveOptions?> showPaymentRequestApproveSheet(
  BuildContext context, {
  required PaymentRequest request,
  required List<WalletCard> walletCards,
}) async {
  final totalAvailable = walletCards.fold<double>(
    0,
    (sum, card) => sum + card.availableBalance,
  );
  final needsBackup = totalAvailable < request.amount;
  final familyCards = await _loadFamilyCards();
  if (!context.mounted) return null;

  var useBackup = needsBackup && familyCards.isNotEmpty;
  FamilyPaymentCard? selectedFamilyCard =
      familyCards.where((card) => card.isBackup && card.isActive).firstOrNull ??
      familyCards.where((card) => card.isActive).firstOrNull;

  return showModalBottomSheet<PaymentRequestApproveOptions>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Aprobar solicitud',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  DisplayFormatters.formatMoney(
                    request.amount,
                    currency: request.currency,
                  ),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (request.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(request.description),
                ],
                const SizedBox(height: AppSpacing.md),
                if (needsBackup) ...[
                  Text(
                    'Tu saldo disponible no alcanza. Puedes usar tarjeta de respaldo familiar.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Usar tarjeta de respaldo'),
                    value: useBackup,
                    onChanged: familyCards.isEmpty
                        ? null
                        : (value) => setState(() => useBackup = value),
                  ),
                ],
                if (useBackup && familyCards.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: selectedFamilyCard?.id,
                    decoration: const InputDecoration(
                      labelText: 'Tarjeta familiar',
                      prefixIcon: Icon(Icons.credit_card_outlined),
                    ),
                    items: familyCards
                        .map(
                          (card) => DropdownMenuItem(
                            value: card.id,
                            child: Text(
                              '${card.alias.isNotEmpty ? card.alias : card.brand} · ${card.maskedNumber}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      selectedFamilyCard = familyCards
                          .where((card) => card.id == value)
                          .firstOrNull;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                FilledButton(
                  onPressed: () {
                    if (needsBackup &&
                        useBackup &&
                        selectedFamilyCard == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecciona una tarjeta de respaldo.'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(
                      context,
                      PaymentRequestApproveOptions(
                        useBackupCard: useBackup,
                        familyPaymentCardId: useBackup
                            ? selectedFamilyCard?.id
                            : null,
                      ),
                    );
                  },
                  child: const Text('Confirmar aprobación'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<List<FamilyPaymentCard>> _loadFamilyCards() async {
  final result = await getIt<FamilyPaymentsRepository>().listCards();
  return result.when(
    success: (cards) => cards.where((card) => card.isActive).toList(),
    failure: (_) => const [],
  );
}
