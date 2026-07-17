import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/display_labels.dart';
import '../../../../shared/widgets/ciervo_chip_tag.dart';

class HomeCategoryList extends StatelessWidget {
  const HomeCategoryList({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    super.key,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = selectedCategory == category;

          return CiervoChipTag(
            label: _label(category),
            selected: selected,
            onSelected: (_) => onCategorySelected(category),
          );
        },
      ),
    );
  }

  String _label(String category) => DisplayLabels.categoryLabel(category);
}
