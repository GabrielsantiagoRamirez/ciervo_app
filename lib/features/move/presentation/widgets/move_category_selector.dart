import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/move_enums.dart';
import '../utils/move_labels.dart';

/// Selector horizontal de categoría de vehículo.
class MoveCategorySelector extends StatelessWidget {
  const MoveCategorySelector({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final MoveVehicleCategory selected;
  final ValueChanged<MoveVehicleCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: MoveVehicleCategory.values.map((category) {
        final isSelected = category == selected;
        return ChoiceChip(
          selected: isSelected,
          onSelected: (_) => onChanged(category),
          avatar: Icon(
            MoveLabels.vehicleCategoryIcon(category),
            size: 18,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          label: Text(MoveLabels.vehicleCategory(category)),
        );
      }).toList(),
    );
  }
}
