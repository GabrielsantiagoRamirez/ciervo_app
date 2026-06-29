import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_component_styles.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/profile_data.dart';
import '../../../media/presentation/authenticated_media_image.dart';

class ProfileExperienceCard extends StatelessWidget {
  const ProfileExperienceCard({required this.experience, super.key});

  final ProfileExperience experience;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.card,
      child: SizedBox(
        width: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AuthenticatedMediaImage(
              mediaId: experience.imageUrl,
              thumbnail: true,
              fit: BoxFit.cover,
              errorWidget: const ColoredBox(color: AppColors.surfaceTop),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppComponentStyles.cardOverlayGradient,
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    experience.title,
                    style: AppTextStyles.title.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    experience.subtitle,
                    style: AppTextStyles.bodyMuted.copyWith(
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
