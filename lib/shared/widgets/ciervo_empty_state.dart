import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'ciervo_button.dart';
import 'ciervo_card.dart';

class CiervoEmptyState extends StatelessWidget {
  const CiervoEmptyState({
    required this.title,
    required this.description,
    super.key,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CiervoCard(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            CiervoButton(
              label: actionLabel!,
              icon: Icons.refresh,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
