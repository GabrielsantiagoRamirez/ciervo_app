import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/experience/experience_mode.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({required this.mode, required this.onChangeMode, super.key});

  final ExperienceMode mode;
  final VoidCallback onChangeMode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('CIERVO', style: AppTextStyles.title),
        const Spacer(),
        TextButton.icon(
          onPressed: onChangeMode,
          icon: Icon(
            mode == ExperienceMode.day
                ? Icons.wb_sunny_outlined
                : Icons.nightlight_outlined,
          ),
          label: Text(mode.label),
        ),
      ],
    );
  }
}
