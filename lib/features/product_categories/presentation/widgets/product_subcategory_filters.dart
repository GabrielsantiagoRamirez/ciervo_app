import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_chip_tag.dart';
import '../../data/product_categories_repository.dart';
import '../../domain/entities/product_category.dart';

class ProductSubcategoryFilters extends StatefulWidget {
  const ProductSubcategoryFilters({
    required this.businessCategoryId,
    this.onSelected,
    super.key,
  });

  final int businessCategoryId;
  final ValueChanged<ProductCategory?>? onSelected;

  @override
  State<ProductSubcategoryFilters> createState() =>
      _ProductSubcategoryFiltersState();
}

class _ProductSubcategoryFiltersState extends State<ProductSubcategoryFilters> {
  late Future<List<ProductCategory>> _categories;
  ProductCategory? _selected;

  @override
  void initState() {
    super.initState();
    _categories = _load();
  }

  @override
  void didUpdateWidget(covariant ProductSubcategoryFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.businessCategoryId != widget.businessCategoryId) {
      _selected = null;
      _categories = _load();
    }
  }

  Future<List<ProductCategory>> _load() async {
    final result = await getIt<ProductCategoriesRepository>().byBusinessCategory(
      widget.businessCategoryId,
    );
    return result.when(
      success: (categories) => categories,
      failure: (_) => const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductCategory>>(
      future: _categories,
      builder: (context, snapshot) {
        final categories = snapshot.data ?? const <ProductCategory>[];
        if (snapshot.connectionState != ConnectionState.done ||
            categories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtrar productos y servicios',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  CiervoChipTag(
                    label: 'Todos',
                    selected: _selected == null,
                    onSelected: (_) => _select(null),
                  ),
                  ...categories.map(
                    (category) => CiervoChipTag(
                      label:
                          category.name.isEmpty ? category.code : category.name,
                      selected: _selected?.id == category.id,
                      onSelected: (_) => _select(category),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _select(ProductCategory? category) {
    setState(() => _selected = category);
    widget.onSelected?.call(category);
  }
}
