import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';

/// Pantalla de espera durante migración legacy → verificación OTP.
class MigrationSplashWidget extends StatelessWidget {
  const MigrationSplashWidget({
    super.key,
    required this.onRetry,
    this.showRetry = false,
    this.isLoading = true,
    this.title = 'Verificando tu cuenta',
    this.subtitle =
        'Por tu seguridad, necesitamos confirmar tu identidad. '
        'Esto puede tardar uno o dos minutos.',
  });

  final VoidCallback onRetry;
  final bool showRetry;
  final bool isLoading;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isLoading) ...[
          const Center(
            child: SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        Text(
          title,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        if (showRetry) ...[
          const SizedBox(height: AppSpacing.xl),
          CiervoButton(
            label: 'Reintentar',
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        ],
      ],
    );
  }
}
