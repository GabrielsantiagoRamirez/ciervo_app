import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/marketplace_models.dart';

Future<MarketplaceFeedQuery?> showMarketplaceFiltersSheet({
  required BuildContext context,
  required MarketplaceFeedQuery initial,
  required MarketplaceFiltersCatalog catalog,
}) {
  return showModalBottomSheet<MarketplaceFeedQuery>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _MarketplaceFiltersSheet(
      initial: initial,
      catalog: catalog,
    ),
  );
}

class _MarketplaceFiltersSheet extends StatefulWidget {
  const _MarketplaceFiltersSheet({
    required this.initial,
    required this.catalog,
  });

  final MarketplaceFeedQuery initial;
  final MarketplaceFiltersCatalog catalog;

  @override
  State<_MarketplaceFiltersSheet> createState() =>
      _MarketplaceFiltersSheetState();
}

class _MarketplaceFiltersSheetState extends State<_MarketplaceFiltersSheet> {
  late MarketplaceFeedQuery _query;

  @override
  void initState() {
    super.initState();
    _query = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtros marketplace', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.md),
            Text('Categoría', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _query.categoryId == null,
                  onSelected: (_) => setState(
                    () => _query = _query.copyWith(clearCategory: true),
                  ),
                ),
                for (final category in widget.catalog.categories)
                  ChoiceChip(
                    label: Text(category.name),
                    selected: _query.categoryId == category.id,
                    onSelected: (_) => setState(
                      () => _query = _query.copyWith(
                        categoryId: category.id,
                        categoria: category.name,
                      ),
                    ),
                  ),
              ],
            ),
            if (widget.catalog.cities.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Ciudad', style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  ChoiceChip(
                    label: const Text('Cualquiera'),
                    selected: _query.ciudad == null,
                    onSelected: (_) => setState(
                      () => _query = _query.copyWith(clearCity: true),
                    ),
                  ),
                  for (final city in widget.catalog.cities.take(12))
                    ChoiceChip(
                      label: Text(city),
                      selected: _query.ciudad == city,
                      onSelected: (_) => setState(
                        () => _query = _query.copyWith(ciudad: city),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text('Experiencia', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                FilterChip(
                  label: const Text('Día'),
                  selected: _query.dia == true,
                  onSelected: (v) => setState(
                    () => _query = _query.copyWith(
                      clearDayModes: true,
                      dia: v ? true : null,
                    ),
                  ),
                ),
                FilterChip(
                  label: const Text('Noche'),
                  selected: _query.noche == true,
                  onSelected: (v) => setState(
                    () => _query = _query.copyWith(
                      clearDayModes: true,
                      noche: v ? true : null,
                    ),
                  ),
                ),
                FilterChip(
                  label: const Text('24h'),
                  selected: _query.horas24 == true,
                  onSelected: (v) => setState(
                    () => _query = _query.copyWith(
                      clearDayModes: true,
                      horas24: v ? true : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Con delivery'),
              value: _query.delivery == true,
              onChanged: (v) => setState(
                () => _query = v
                    ? _query.copyWith(delivery: true)
                    : _query.copyWith(clearDelivery: true),
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Solo cashback'),
              value: _query.onlyCashback == true || _query.cashback == true,
              onChanged: (v) => setState(
                () => _query = v
                    ? _query.copyWith(onlyCashback: true, cashback: true)
                    : _query.copyWith(clearCashback: true),
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Solo puntos'),
              value: _query.onlyPoints == true,
              onChanged: (v) => setState(
                () => _query = v
                    ? _query.copyWith(onlyPoints: true)
                    : _query.copyWith(clearOnlyPoints: true),
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ordenar por popular'),
              value: _query.order == 'popular',
              onChanged: (v) => setState(
                () => _query = v
                    ? _query.copyWith(order: 'popular')
                    : _query.copyWith(clearOrder: true),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(
                    const MarketplaceFeedQuery(),
                  ),
                  child: const Text('Limpiar'),
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.dayText,
                  ),
                  onPressed: () => Navigator.of(context).pop(_query),
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
