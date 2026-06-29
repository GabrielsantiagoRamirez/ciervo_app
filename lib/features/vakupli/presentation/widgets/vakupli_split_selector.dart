import 'package:flutter/material.dart';

import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/vakupli_plan.dart';

class VakupliSplitSelector extends StatelessWidget {
  const VakupliSplitSelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final VakupliSplitOption selected;
  final ValueChanged<VakupliSplitOption> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadii.input,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SplitOptionTile(
              label: 'Equal split',
              selected: selected == VakupliSplitOption.equal,
              onTap: () => onChanged(VakupliSplitOption.equal),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _SplitOptionTile(
              label: 'Custom split',
              selected: selected == VakupliSplitOption.custom,
              onTap: () => onChanged(VakupliSplitOption.custom),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitOptionTile extends StatelessWidget {
  const _SplitOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = colorScheme.primary;
    final selectedText = AppColors.dayText;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.input,
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected ? selectedBg : colorScheme.surface,
          borderRadius: AppRadii.input,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colorScheme.onSurface.withValues(
                      alpha: isDark ? 0.2 : 0.14,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: selected ? selectedText : colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
