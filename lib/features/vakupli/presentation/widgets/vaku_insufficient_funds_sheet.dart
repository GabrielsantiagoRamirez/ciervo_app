import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_formatters.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../family_payments/presentation/pages/family_payment_methods_page.dart';
import '../../../wallet/domain/entities/wallet_card.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../../wallet/presentation/pages/recharge_page.dart';
import '../../../wallet/presentation/pages/wallet_page.dart';

enum VakuFundsAction { recharge, pickCard, addCard, cancel }

class VakuFundsResolution {
  const VakuFundsResolution({required this.action, this.card});

  final VakuFundsAction action;
  final WalletCard? card;
}

/// Sheet cuando no alcanza el saldo para pagar Vaku.
Future<VakuFundsResolution?> showVakuInsufficientFundsSheet(
  BuildContext context, {
  required double amountDue,
  required double availableBalance,
  required String currency,
  required List<WalletCard> cards,
}) {
  final shortfall = (amountDue - availableBalance).clamp(0, double.infinity);
  final payableCards = cards
      .where((card) => card.canSpend(amountDue))
      .toList(growable: false);

  return showModalBottomSheet<VakuFundsResolution>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Saldo insuficiente',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Debes pagar ${DisplayFormatters.formatMoney(amountDue, currency: currency)}.\n'
              'Tienes ${DisplayFormatters.formatMoney(availableBalance, currency: currency)}.\n'
              'Te faltan ${DisplayFormatters.formatMoney(shortfall, currency: currency)}.',
            ),
            const SizedBox(height: AppSpacing.md),
            if (payableCards.isNotEmpty) ...[
              Text(
                'Elige una tarjeta con saldo',
                style: Theme.of(sheetContext).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...payableCards.map(
                (card) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.credit_card),
                  title: Text(card.name),
                  subtitle: Text(
                    DisplayFormatters.formatMoney(
                      card.availableBalance,
                      currency: card.currency.isNotEmpty
                          ? card.currency
                          : currency,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    VakuFundsResolution(
                      action: VakuFundsAction.pickCard,
                      card: card,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ] else if (cards.isNotEmpty) ...[
              Text(
                'Ninguna tarjeta tiene saldo suficiente. Recarga o agrega otra.',
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
            ] else ...[
              Text(
                'No tienes tarjetas wallet. Agrega una o recarga desde Wallet.',
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            CiervoButton(
              label: 'Recargar wallet',
              icon: Icons.add_card_outlined,
              onPressed: () => Navigator.pop(
                sheetContext,
                const VakuFundsResolution(action: VakuFundsAction.recharge),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(
                sheetContext,
                const VakuFundsResolution(action: VakuFundsAction.addCard),
              ),
              icon: const Icon(Icons.credit_score_outlined),
              label: Text(
                cards.isEmpty
                    ? 'Agregar / ver tarjetas'
                    : 'Administrar tarjetas',
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                sheetContext,
                const VakuFundsResolution(action: VakuFundsAction.cancel),
              ),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> openVakuFundsAction(
  BuildContext context,
  VakuFundsResolution resolution, {
  required List<WalletCard> cards,
}) async {
  switch (resolution.action) {
    case VakuFundsAction.recharge:
      final card =
          resolution.card ??
          cards.where((c) => c.isPrimary).firstOrNull ??
          (cards.isNotEmpty ? cards.first : null);
      if (card != null) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => RechargePage(card: card)),
        );
      } else {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const WalletPage()));
      }
    case VakuFundsAction.addCard:
      // Métodos de pago (Visa/MC) + wallet Ciervo.
      final goFamily = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Agregar tarjeta'),
          content: const Text(
            'Puedes ir a Wallet Ciervo o a Métodos de pago (Visa/Mastercard).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Wallet Ciervo'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Métodos de pago'),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      if (goFamily == true) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const FamilyPaymentMethodsPage(),
          ),
        );
      } else {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const WalletPage()));
      }
    case VakuFundsAction.pickCard:
    case VakuFundsAction.cancel:
      break;
  }
}

Future<List<WalletCard>> loadWalletCards() async {
  final result = await getIt<WalletRepository>().cards();
  return result.when(
    success: (cards) => cards,
    failure: (_) => const <WalletCard>[],
  );
}
