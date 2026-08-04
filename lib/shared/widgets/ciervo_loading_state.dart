import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'ciervo_brand_loader.dart';
import 'ciervo_skeleton.dart';
import 'staggered_reveal.dart';

class CiervoLoadingState extends StatelessWidget {
  const CiervoLoadingState({
    super.key,
    this.itemCount = 4,
    this.message = 'Cargando Ciervo',
    this.showSkeletons = true,
  });

  final int itemCount;
  final String message;
  final bool showSkeletons;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: CiervoBrandLoader(message: message, compact: true),
        ),
        if (showSkeletons)
          ...List.generate(
            itemCount,
            (index) => StaggeredReveal(
              index: index,
              baseDelay: const Duration(milliseconds: 70),
              beginScale: 0.98,
              child: const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: CiervoSkeleton(width: double.infinity, height: 84),
              ),
            ),
          ),
      ],
    );
  }
}
