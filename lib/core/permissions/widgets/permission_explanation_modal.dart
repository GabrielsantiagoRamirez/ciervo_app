import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../permission_kind.dart';
import '../../../shared/widgets/ciervo_button.dart';

/// Modal reutilizable que explica por qué se solicita un permiso.
Future<bool> showPermissionExplanationModal(
  BuildContext context, {
  required AppPermissionKind kind,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.background,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              kind.title,
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              kind.explanation,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            CiervoButton(
              label: 'Permitir acceso',
              icon: Icons.check_circle_outline,
              onPressed: () => Navigator.pop(ctx, true),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ahora no'),
            ),
          ],
        ),
      ),
    ),
  );
  return result == true;
}
