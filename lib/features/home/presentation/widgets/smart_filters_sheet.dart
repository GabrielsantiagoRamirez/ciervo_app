import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../discovery/domain/entities/discovery_smart_filters.dart';

Future<DiscoverySmartFilters?> showSmartFiltersSheet({
  required BuildContext context,
  required DiscoverySmartFilters initial,
}) {
  return showModalBottomSheet<DiscoverySmartFilters>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SmartFiltersSheet(initial: initial),
  );
}

class SmartFiltersSheet extends StatefulWidget {
  const SmartFiltersSheet({required this.initial, super.key});

  final DiscoverySmartFilters initial;

  @override
  State<SmartFiltersSheet> createState() => _SmartFiltersSheetState();
}

class _SmartFiltersSheetState extends State<SmartFiltersSheet> {
  static const _ratingOptions = <double?>[null, 3.5, 4.0, 4.5];

  late DiscoverySmartFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initial;
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filtros', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Radio: ${_filters.radiusKm.toStringAsFixed(0)} km',
              style: AppTextStyles.label,
            ),
            Slider(
              min: 5,
              max: 50,
              divisions: 9,
              value: _filters.radiusKm.clamp(5, 50),
              label: '${_filters.radiusKm.toStringAsFixed(0)} km',
              onChanged: (value) {
                setState(() {
                  _filters = _filters.copyWith(radiusKm: value.roundToDouble());
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Calificación mínima', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final rating in _ratingOptions)
                  ChoiceChip(
                    label: Text(rating == null ? 'Cualquiera' : '$rating+'),
                    selected: _filters.minRating == rating,
                    onSelected: (_) {
                      setState(() {
                        _filters = rating == null
                            ? _filters.copyWith(clearMinRating: true)
                            : _filters.copyWith(minRating: rating);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _FilterSwitch(
              title: 'Solo abiertos ahora',
              value: _filters.openNow,
              onChanged: (v) =>
                  setState(() => _filters = _filters.copyWith(openNow: v)),
            ),
            _FilterSwitch(
              title: 'Acepta pagos CIERVO',
              value: _filters.acceptsCiervoPayments,
              onChanged: (v) => setState(
                () => _filters = _filters.copyWith(acceptsCiervoPayments: v),
              ),
            ),
            _FilterSwitch(
              title: 'Tiene delivery',
              value: _filters.hasDelivery,
              onChanged: (v) =>
                  setState(() => _filters = _filters.copyWith(hasDelivery: v)),
            ),
            _FilterSwitch(
              title: 'Requiere reserva',
              value: _filters.requiresReservation,
              onChanged: (v) => setState(
                () => _filters = _filters.copyWith(requiresReservation: v),
              ),
            ),
            _FilterSwitch(
              title: 'Tiene promociones',
              value: _filters.hasPromotions,
              onChanged: (v) => setState(
                () => _filters = _filters.copyWith(hasPromotions: v),
              ),
            ),
            _FilterSwitch(
              title: 'Apto familias',
              value: _filters.familyFriendly,
              onChanged: (v) => setState(
                () => _filters = _filters.copyWith(familyFriendly: v),
              ),
            ),
            _FilterSwitch(
              title: 'Pet friendly',
              value: _filters.petFriendly,
              onChanged: (v) =>
                  setState(() => _filters = _filters.copyWith(petFriendly: v)),
            ),
            _FilterSwitch(
              title: 'Accesible',
              value: _filters.accessible,
              onChanged: (v) =>
                  setState(() => _filters = _filters.copyWith(accessible: v)),
            ),
            _FilterSwitch(
              title: 'Estacionamiento',
              value: _filters.hasParking,
              onChanged: (v) =>
                  setState(() => _filters = _filters.copyWith(hasParking: v)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => _filters = const DiscoverySmartFilters());
                  },
                  child: const Text('Limpiar'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_filters),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.dayText,
                  ),
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

class _FilterSwitch extends StatelessWidget {
  const _FilterSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppTextStyles.body),
      value: value,
      onChanged: onChanged,
    );
  }
}
