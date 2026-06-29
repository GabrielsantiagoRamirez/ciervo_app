import 'package:flutter/material.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/profile_data.dart';

class ProfileReviewTile extends StatelessWidget {
  const ProfileReviewTile({required this.review, super.key});

  final ProfileReview review;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadii.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(review.placeName, style: AppTextStyles.label),
              ),
              Text('${review.rating} ★', style: AppTextStyles.label),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(review.comment, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.xxs),
          Text(review.timeLabel, style: AppTextStyles.bodyMuted),
        ],
      ),
    );
  }
}
