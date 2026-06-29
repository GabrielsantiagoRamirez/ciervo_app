import 'package:flutter/material.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/vakupli_plan.dart';

class VakupliChatBubble extends StatelessWidget {
  const VakupliChatBubble({
    required this.message,
    super.key,
  });

  final VakupliMessage message;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isCurrentUser;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark
        ? colorScheme.surface.withValues(alpha: 0.55)
        : colorScheme.surface.withValues(alpha: 0.78);
    final otherBubbleColor = isDark ? AppColors.surface : AppColors.daySurface;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.xxs),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: isDark ? 0.12 : 0.2),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isMe ? colorScheme.primary : otherBubbleColor,
            borderRadius: BorderRadius.circular(AppRadii.md - 2),
            border: isMe
                ? null
                : Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                  child: Text(message.senderName, style: AppTextStyles.label),
                ),
              Text(
                message.text,
                style: AppTextStyles.body.copyWith(
                  color: isMe ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                message.timeLabel,
                style: AppTextStyles.bodyMuted.copyWith(
                  color: isMe
                      ? colorScheme.onPrimary.withValues(alpha: 0.8)
                      : colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
