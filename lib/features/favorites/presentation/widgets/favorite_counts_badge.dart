import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class FavoriteCountsBadge extends StatelessWidget {
  const FavoriteCountsBadge({
    required this.bonuses,
    required this.campaigns,
    super.key,
  });

  final int bonuses;
  final int campaigns;

  @override
  Widget build(BuildContext context) {
    if (bonuses <= 0 && campaigns <= 0) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.xxs,
      children: [
        if (bonuses > 0)
          _Chip(
            icon: Icons.local_offer_outlined,
            label: '$bonuses',
            tooltip: 'Bonos activos',
          ),
        if (campaigns > 0)
          _Chip(
            icon: Icons.campaign_outlined,
            label: '$campaigns',
            tooltip: 'Campanas activas',
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.tooltip,
  });

  final IconData icon;
  final String label;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: AppColors.primary),
              const SizedBox(width: 2),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
}
