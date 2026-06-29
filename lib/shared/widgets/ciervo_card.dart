import 'package:flutter/material.dart';

import '../../core/theme/app_component_styles.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

class CiervoCard extends StatelessWidget {
  const CiervoCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.height,
    this.width,
    this.showGradientOverlay = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? height;
  final double? width;
  final bool showGradientOverlay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: AppComponentStyles.cardDecoration(theme.colorScheme.surface, isDark),
      child: Stack(
        fit: StackFit.loose,
        children: [
          if (showGradientOverlay)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadii.card,
                  gradient: AppComponentStyles.cardOverlayGradient,
                ),
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
