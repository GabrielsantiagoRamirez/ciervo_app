import 'package:flutter/material.dart';

import '../../core/kids/selected_kid_context.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class KidsModeBanner extends StatelessWidget {
  const KidsModeBanner({
    required this.kidContext,
    required this.onExit,
    super.key,
  });

  final SelectedKidContext kidContext;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    if (!kidContext.isActive) return const SizedBox.shrink();
    final name = kidContext.kidName;
    final label = name == null || name.isEmpty
        ? 'Modo menor activo'
        : 'Navegando como $name';

    return Material(
      color: AppColors.primary.withValues(alpha: 0.14),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(Icons.child_care_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: onExit,
              child: const Text('Salir del modo menor'),
            ),
          ],
        ),
      ),
    );
  }
}
