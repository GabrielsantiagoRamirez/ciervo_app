import 'package:flutter/material.dart';

import '../../features/chat/presentation/pages/chat_inbox_page.dart';
import '../../features/kids/presentation/pages/guardian_pay_for_me_page.dart';
import '../../features/wallet/presentation/pages/request_money_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';

/// Diálogo reutilizable cuando el usuario no tiene saldo suficiente.
Future<void> showInsufficientBalanceDialog(
  BuildContext context, {
  String? description,
  double? amount,
  String? currency,
  String? chatConversationId,
  int? businessId,
  int? bookingId,
}) async {
  final body = description ??
      (amount != null
          ? 'Necesitas ${currency ?? 'COP'} ${amount.toStringAsFixed(0)} y tu saldo no alcanza.'
          : 'No tienes saldo suficiente en tu wallet.');

  final action = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Saldo insuficiente'),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cerrar'),
        ),
        if (chatConversationId != null)
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'chat'),
            child: const Text('Compartir en chat'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'request'),
          child: const Text('Pedir que me paguen'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'tutor'),
          child: const Text('Pedir a tutor'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, 'recharge'),
          child: const Text('Recargar'),
        ),
      ],
    ),
  );

  if (!context.mounted || action == null) return;

  switch (action) {
    case 'chat':
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RequestMoneyPage(
            chatConversationId: chatConversationId,
            businessId: businessId,
            bookingId: bookingId,
            initialAmount: amount,
            initialCurrency: currency,
          ),
        ),
      );
    case 'request':
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RequestMoneyPage(
            chatConversationId: chatConversationId,
            businessId: businessId,
            bookingId: bookingId,
            initialAmount: amount,
            initialCurrency: currency,
          ),
        ),
      );
    case 'tutor':
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const GuardianPayForMePage()),
      );
    case 'recharge':
    case 'wallet':
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const WalletPage()),
      );
  }
}

/// Banner compacto para recordar acciones de recarga cuando el saldo es bajo.
class LowBalanceBanner extends StatelessWidget {
  const LowBalanceBanner({
    required this.balance,
    required this.currency,
    this.threshold = 5000,
    super.key,
  });

  final double balance;
  final String currency;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    if (balance > threshold) return const SizedBox.shrink();

    return Card(
      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Saldo bajo: $currency ${balance.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Recarga, pide apoyo a tu tutor o comparte una solicitud en el chat.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const WalletPage()),
                  ),
                  icon: const Icon(Icons.add_card_outlined, size: 18),
                  label: const Text('Recargar'),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const GuardianPayForMePage(),
                    ),
                  ),
                  icon: const Icon(Icons.family_restroom, size: 18),
                  label: const Text('Tutor'),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ChatInboxPage()),
                  ),
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: const Text('Chat'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
