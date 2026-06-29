import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../media/presentation/authenticated_media_image.dart';
import '../../domain/entities/bonus.dart';

class BonusCard extends StatelessWidget {
  const BonusCard({
    required this.bonus,
    required this.onTap,
    this.compact = false,
    super.key,
  });

  final Bonus bonus;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: AppRadii.card,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadii.card,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.surfaceHigh, AppColors.surfaceLow],
            ),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
          ),
          padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BonusImage(bonus: bonus, compact: compact),
              SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bonus.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.title.copyWith(fontSize: compact ? 14 : 16),
                          ),
                        ),
                        _StatusChip(status: bonus.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      bonus.businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      bonus.benefitLabel,
                      style: AppTextStyles.label.copyWith(color: AppColors.primary),
                    ),
                    if (!compact && bonus.description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        bonus.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMuted.copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _BonusImage extends StatelessWidget {
  const _BonusImage({required this.bonus, required this.compact});

  final Bonus bonus;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 56.0 : 72.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: SizedBox(
        width: size,
        height: size,
        child: (bonus.imageUrl ?? '').isNotEmpty
            ? AuthenticatedMediaImage(
                mediaId: bonus.imageUrl!,
                thumbnail: true,
                fit: BoxFit.cover,
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceTop,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.local_offer_outlined, color: AppColors.primary),
              ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final BonusStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BonusStatus.active => AppColors.success,
      BonusStatus.claimed => AppColors.info,
      BonusStatus.redeemed => AppColors.textMuted,
      BonusStatus.expired || BonusStatus.soldOut => AppColors.error,
      _ => AppColors.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: AppRadii.chip,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.label.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}
