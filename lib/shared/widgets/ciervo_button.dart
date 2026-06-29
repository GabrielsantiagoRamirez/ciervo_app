import 'package:flutter/material.dart';

import '../../core/theme/app_component_styles.dart';

enum CiervoButtonVariant { primary, secondary, danger }

enum CiervoButtonState { normal, loading, success, error }

class CiervoButton extends StatelessWidget {
  const CiervoButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = CiervoButtonVariant.primary,
    this.state = CiervoButtonState.normal,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final CiervoButtonVariant variant;
  final CiervoButtonState state;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = switch (variant) {
      CiervoButtonVariant.primary => AppComponentStyles.primaryButton(colorScheme),
      CiervoButtonVariant.secondary => AppComponentStyles.secondaryButton(colorScheme),
      CiervoButtonVariant.danger => AppComponentStyles.dangerButton(colorScheme),
    };
    final effectiveIcon = switch (state) {
      CiervoButtonState.success => Icons.check_circle_outline,
      CiervoButtonState.error => Icons.error_outline,
      _ => icon ?? Icons.chevron_right,
    };

    return ElevatedButton.icon(
      onPressed: state == CiervoButtonState.loading ? null : onPressed,
      style: style,
      icon: state == CiervoButtonState.loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onPrimary,
              ),
            )
          : Icon(effectiveIcon),
      label: Text(label),
    );
  }
}
