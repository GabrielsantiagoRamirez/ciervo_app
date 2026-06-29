import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';

class CiervoSkeleton extends StatelessWidget {
  const CiervoSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = AppRadii.input,
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceTop.withValues(alpha: 0.55),
        borderRadius: borderRadius,
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}
