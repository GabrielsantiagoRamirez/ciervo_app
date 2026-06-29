import 'package:flutter/material.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/ciervo_card.dart';
import '../../domain/entities/profile_data.dart';

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({required this.profile, super.key});

  final ProfileData profile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CiervoCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: AppRadii.chip,
            ),
            alignment: Alignment.center,
            child: Text(
              profile.avatarInitials,
              style: AppTextStyles.title.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.xxs),
                Text(profile.membershipLabel, style: AppTextStyles.bodyMuted),
              ],
            ),
          ),
          Icon(Icons.verified, color: colorScheme.primary),
        ],
      ),
    );
  }
}
