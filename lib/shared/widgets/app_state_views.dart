import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'ciervo_button.dart';
import 'ciervo_card.dart';
import 'ciervo_error_state.dart';
import 'ciervo_empty_state.dart';

/// Alias estándar para estados de error en toda la app.
typedef AppErrorView = CiervoErrorState;

/// Alias estándar para estados vacíos.
typedef AppEmptyState = CiervoEmptyState;

/// Botón con estado de carga integrado.
class AppLoadingButton extends StatelessWidget {
  const AppLoadingButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return CiervoButton(
      label: loading ? 'Procesando…' : label,
      icon: icon,
      state: loading ? CiervoButtonState.loading : CiervoButtonState.normal,
      onPressed: loading ? null : onPressed,
    );
  }
}

/// Tarjeta de reintento reutilizable.
class AppRetryCard extends StatelessWidget {
  const AppRetryCard({
    required this.title,
    required this.description,
    required this.onRetry,
    super.key,
  });

  final String title;
  final String description;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return CiervoCard(
      child: AppErrorView(
        title: title,
        description: description,
        onRetry: onRetry,
      ),
    );
  }
}

/// SnackBar centralizado con estilo consistente.
abstract final class AppSnackBar {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message);
  }

  static void error(BuildContext context, String message) {
    show(context, message);
  }
}
