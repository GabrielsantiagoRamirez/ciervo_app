import 'package:flutter/material.dart';

import '../../core/theme/app_component_styles.dart';
import '../../core/theme/app_radii.dart';

class CiervoBottomNavSurface extends StatelessWidget {
  const CiervoBottomNavSurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: AppRadii.card,
      child: DecoratedBox(
        decoration: AppComponentStyles.bottomNavigationSurface(
          theme.colorScheme,
          isDark,
        ),
        child: child,
      ),
    );
  }
}
