import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/permissions/app_permission_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/ciervo_button.dart';

/// Explica y solicita ubicación + notificaciones al abrir la app.
abstract final class EntryPermissionsPrompt {
  static Future<void> showIfNeeded(BuildContext context) async {
    final service = getIt<AppPermissionService>();
    if (await service.hasRequiredPermissions()) return;
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
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
                'Permisos de Ciervo Club',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              const _PermissionRow(
                icon: Icons.location_on_outlined,
                title: 'Ubicación',
                description:
                    'Necesaria para negocios cercanos, delivery, registro y seguridad de pagos.',
              ),
              const SizedBox(height: AppSpacing.sm),
              const _PermissionRow(
                icon: Icons.notifications_active_outlined,
                title: 'Notificaciones',
                description:
                    'Te avisamos de mensajes, pagos, recargas, transferencias y movimientos importantes.',
              ),
              const SizedBox(height: AppSpacing.lg),
              CiervoButton(
                label: 'Permitir acceso',
                icon: Icons.check_circle_outline,
                onPressed: () => Navigator.pop(ctx),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Ahora no'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
