import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/universal_nfc_payment.dart';

class SavedPaymentMethodTile extends StatelessWidget {
  const SavedPaymentMethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final SavedPaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon {
    switch (method.type.toLowerCase()) {
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'mercadopago':
        return Icons.payments_outlined;
      case 'visa':
      case 'mastercard':
        return Icons.credit_card_outlined;
      default:
        return Icons.payment_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: selected,
      selectedTileColor: theme.colorScheme.primaryContainer.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.22 : 0.35,
      ),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(_icon, size: 20),
      ),
      title: Text(method.label),
      subtitle: Text(
        [
          if (method.isDefault) 'Predeterminado',
          method.type,
        ].join(' · '),
      ),
      trailing: selected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : const Icon(Icons.radio_button_off_outlined),
      onTap: onTap,
    );
  }
}
