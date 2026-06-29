import 'package:flutter/material.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/vakupli_plan.dart';

class VakupliFriendsGroup extends StatelessWidget {
  const VakupliFriendsGroup({
    required this.friends,
    super.key,
  });

  final List<VakupliFriend> friends;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarsWidth = (friends.length * 34) + 18.0;

    return Row(
      children: [
        SizedBox(
          width: avatarsWidth,
          height: 62,
          child: Stack(
            children: [
              Positioned(
                left: 22,
                right: 8,
                top: 30,
                child: Container(
                  height: 2,
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
              for (var i = 0; i < friends.length; i++)
                Positioned(
                  left: i * 34,
                  top: 5,
                  child: Tooltip(
                    message: friends[i].name,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: i == 0 ? colorScheme.primary : colorScheme.surface,
                        borderRadius: AppRadii.chip,
                        border: Border.all(
                          width: 1.2,
                          color: isDark
                              ? colorScheme.onSurface.withValues(alpha: 0.2)
                              : colorScheme.onSurface.withValues(alpha: 0.28),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        friends[i].initials,
                        style: AppTextStyles.label.copyWith(
                          color: i == 0 ? colorScheme.onPrimary : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppRadii.chip,
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            '${friends.length} amigos',
            style: AppTextStyles.bodyMuted.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
