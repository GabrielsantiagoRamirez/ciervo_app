import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/experience/experience_mode.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    required this.mode,
    required this.onModeChanged,
    required this.onOpenFilters,
    this.activeFilterCount = 0,
    super.key,
  });

  final ExperienceMode mode;
  final ValueChanged<ExperienceMode> onModeChanged;
  final VoidCallback onOpenFilters;
  final int activeFilterCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('CIERVO', style: AppTextStyles.title),
            const Spacer(),
            Badge(
              isLabelVisible: activeFilterCount > 0,
              label: Text('$activeFilterCount'),
              child: IconButton(
                tooltip: 'Filtros',
                onPressed: onOpenFilters,
                icon: const Icon(Icons.tune_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _ExperienceModeToggle(mode: mode, onChanged: onModeChanged),
      ],
    );
  }
}

class _ExperienceModeToggle extends StatelessWidget {
  const _ExperienceModeToggle({required this.mode, required this.onChanged});

  final ExperienceMode mode;
  final ValueChanged<ExperienceMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDay = mode == ExperienceMode.day;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDay ? const Color(0xFFF0E8D4) : const Color(0xFF151516),
        borderRadius: AppRadii.chip,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          for (final option in ExperienceMode.values)
            Expanded(
              child: _Segment(
                label: option.label,
                icon: option.icon,
                selected: mode == option,
                isDayTrack: isDay,
                onTap: () => onChanged(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDayTrack,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool isDayTrack;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unselected =
        isDayTrack ? AppColors.dayTextMuted : AppColors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.chip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [AppColors.primaryHigh, AppColors.goldDark],
                )
              : null,
          borderRadius: AppRadii.chip,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.dayText : AppColors.goldDark,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.dayText : unselected,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
