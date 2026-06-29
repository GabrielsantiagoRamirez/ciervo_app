import 'package:flutter/material.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/place_detail.dart';

class PlaceDetailReviewTile extends StatelessWidget {
  const PlaceDetailReviewTile({
    required this.review,
    super.key,
  });

  final PlaceReview review;

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
              CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.surface.withValues(alpha: 0.92),
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(review.userName, style: AppTextStyles.label),
              const Spacer(),
              Text('${review.rating} ★', style: AppTextStyles.label),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(review.comment, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.xxs),
          Text(review.timeAgo, style: AppTextStyles.bodyMuted),
        ],
      ),
    );
  }
}
