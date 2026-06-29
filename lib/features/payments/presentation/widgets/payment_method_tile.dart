import 'package:flutter/material.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.card,
      child: Ink(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary.withValues(alpha: 0.14) : colorScheme.surface,
          borderRadius: AppRadii.card,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? colorScheme.primary.withValues(alpha: 0.16)
                    : colorScheme.surface.withValues(alpha: isDark ? 0.8 : 0.9),
                borderRadius: AppRadii.input,
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.label),
                  Text(subtitle, style: AppTextStyles.bodyMuted),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
