import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/ciervo_brand_loader.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Color(0xFF161311),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: CiervoBrandLoader(
            message: 'Ciervo Club',
          ),
        ),
      ),
    );
  }
}
