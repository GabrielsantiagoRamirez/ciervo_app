import 'package:flutter/material.dart';

import '../../core/theme/app_component_styles.dart';
import '../../core/theme/app_spacing.dart';

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
    this.dense = false,
    this.showIcon = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final CiervoButtonVariant variant;
  final CiervoButtonState state;
  final IconData? icon;
  /// Padding más compacto (barras inferiores angostas).
  final bool dense;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    var style = switch (variant) {
      CiervoButtonVariant.primary => AppComponentStyles.primaryButton(
        colorScheme,
      ),
      CiervoButtonVariant.secondary => AppComponentStyles.secondaryButton(
        colorScheme,
      ),
      CiervoButtonVariant.danger => AppComponentStyles.dangerButton(
        colorScheme,
      ),
    };
    if (dense) {
      style = style.copyWith(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
        minimumSize: WidgetStateProperty.all(const Size(0, 44)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }

    final effectiveIcon = switch (state) {
      CiervoButtonState.success => Icons.check_circle_outline,
      CiervoButtonState.error => Icons.error_outline,
      _ => icon ?? Icons.chevron_right,
    };

    final labelWidget = Text(
      label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );

    final loadingIcon = SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: colorScheme.onPrimary,
      ),
    );

    if (!showIcon && state == CiervoButtonState.normal) {
      return ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: labelWidget,
      );
    }

    return ElevatedButton.icon(
      onPressed: state == CiervoButtonState.loading ? null : onPressed,
      style: style,
      icon: state == CiervoButtonState.loading
          ? loadingIcon
          : Icon(effectiveIcon, size: dense ? 18 : 22),
      label: labelWidget,
    );
  }
}
