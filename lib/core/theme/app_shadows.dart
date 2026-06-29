import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.shadowWarm,
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> button = [
    BoxShadow(
      color: AppColors.shadowWarmSoft,
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> nav = [
    BoxShadow(
      color: AppColors.shadowWarm,
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
}
