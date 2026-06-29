import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/entities/place_detail.dart';

class PlaceDetailPromotionCard extends StatelessWidget {
  const PlaceDetailPromotionCard({
    required this.promotion,
    super.key,
  });

  final PlacePromotion promotion;

  @override
  Widget build(BuildContext context) {
    return CiervoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(promotion.title, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          Text(promotion.description, style: AppTextStyles.bodyMuted),
        ],
      ),
    );
  }
}
