import 'package:flutter/material.dart';

import '../../../../core/utils/display_labels.dart';
import '../../domain/entities/family_payment_card.dart';

class FamilyPaymentCardTile extends StatelessWidget {
  const FamilyPaymentCardTile({
    required this.card,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final FamilyPaymentCard card;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colors.primaryContainer,
        child: Icon(
          _brandIcon(card.brand),
          color: colors.onPrimaryContainer,
        ),
      ),
      title: Text(
        card.alias.isNotEmpty ? card.alias : card.maskedNumber,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${card.brand.toUpperCase()} · ${card.maskedNumber}'),
          Text('Expira ${card.expirationLabel} · ${DisplayLabels.familyCardStatus(card.status)}'),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (card.isPrimary)
                const Chip(
                  label: Text('Principal'),
                  visualDensity: VisualDensity.compact,
                ),
              if (card.isBackup)
                const Chip(
                  label: Text('Respaldo'),
                  visualDensity: VisualDensity.compact,
                ),
              if (card.isFrozen)
                Chip(
                  label: const Text('Congelada'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: colors.errorContainer,
                ),
            ],
          ),
        ],
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
    );
  }

  IconData _brandIcon(String brand) {
    final normalized = brand.toLowerCase();
    if (normalized.contains('visa')) return Icons.credit_card;
    if (normalized.contains('master')) return Icons.credit_card;
    return Icons.payment;
  }
}
