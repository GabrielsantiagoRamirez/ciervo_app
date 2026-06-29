import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'ciervo_button.dart';
import 'ciervo_card.dart';

class CiervoErrorState extends StatelessWidget {
  const CiervoErrorState({
    required this.title,
    required this.description,
    super.key,
    this.onRetry,
  });

  final String title;
  final String description;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CiervoCard(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 44, color: colorScheme.error),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            CiervoButton(
              label: 'Reintentar',
              icon: Icons.refresh,
              variant: CiervoButtonVariant.secondary,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
