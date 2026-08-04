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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Cómo dividen el pago?',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: AppRadii.input,
          ),
          child: Row(
            children: [
              Expanded(
                child: _SplitOptionTile(
                  label: 'Partes iguales',
                  selected: selected == VakupliSplitOption.equal,
                  onTap: () => onChanged(VakupliSplitOption.equal),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _SplitOptionTile(
                  label: 'Monto personalizado',
                  selected: selected == VakupliSplitOption.custom,
                  onTap: () => onChanged(VakupliSplitOption.custom),
                ),
              ),
            ],
          ),
        ),
      ],
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
    final selectedBg = colorScheme.primary;
    final selectedText = AppColors.dayText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.input,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected ? selectedBg : Colors.transparent,
            borderRadius: AppRadii.input,
            border: Border.all(
              color: selected
                  ? selectedBg
                  : colorScheme.outline.withValues(alpha: 0.35),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: selected ? selectedText : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label.copyWith(
                    color: selected
                        ? selectedText
                        : colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
