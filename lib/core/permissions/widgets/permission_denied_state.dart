import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../permission_kind.dart';
import '../../../shared/widgets/ciervo_card.dart';
import 'open_settings_button.dart';

class PermissionDeniedState extends StatelessWidget {
  const PermissionDeniedState({required this.kind, this.onRetry, super.key});

  final AppPermissionKind kind;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CiervoCard(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 44, color: colorScheme.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Permiso requerido',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            kind.deniedMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            kind.explanation,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (onRetry != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Intentar de nuevo'),
              ),
            ),
          const OpenSettingsButton(),
        ],
      ),
    );
  }
}
