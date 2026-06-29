import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/entities/vakupli_plan.dart';

class VakupliPlanCard extends StatelessWidget {
  const VakupliPlanCard({
    required this.plan,
    super.key,
  });

  final VakupliPlan plan;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.title,
                  style: AppTextStyles.title.copyWith(color: colorScheme.onSurface),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, size: 14, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      plan.statusLabel,
                      style: AppTextStyles.label.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.xxs),
              Text('Tiempo restante: ${plan.timeLeftLabel}', style: AppTextStyles.bodyMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '\$${plan.totalAmount.toStringAsFixed(0)}',
            style: AppTextStyles.display.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text('Total estimado del plan', style: AppTextStyles.bodyMuted),
        ],
      ),
    );
  }
}
