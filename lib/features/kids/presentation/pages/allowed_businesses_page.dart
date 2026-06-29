import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../domain/repositories/kids_repository.dart';
import '../cubit/kids_cubit.dart';
import '../cubit/kids_state.dart';

class AllowedBusinessesPage extends StatelessWidget {
  const AllowedBusinessesPage({required this.childId, super.key});
  final String childId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        KidsCubit(getIt<KidsRepository>())..loadBusinessCandidates(childId),
    child: _AllowedBusinessesView(childId: childId),
  );
}

class _AllowedBusinessesView extends StatefulWidget {
  const _AllowedBusinessesView({required this.childId});
  final String childId;

  @override
  State<_AllowedBusinessesView> createState() => _AllowedBusinessesViewState();
}

class _AllowedBusinessesViewState extends State<_AllowedBusinessesView> {
  final _searchController = TextEditingController();
  final Set<String> _selected = {};
  List<Map<String, dynamic>> _businesses = const [];
  String? _city;
  String? _category;
  bool _initialized = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initialize(dynamic value) {
    if (_initialized || value is! List) return;
    _businesses = value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    _selected.addAll(
      _businesses
          .where((item) => item['isAllowed'] != false)
          .map(_id)
          .where((id) => id.isNotEmpty),
    );
    _initialized = true;
  }

  String _id(Map<String, dynamic> item) =>
      (item['businessId'] ?? item['id'] ?? '').toString();
  String _label(Map<String, dynamic> item, String key) =>
      (item[key] ?? '').toString();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<KidsCubit, KidsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        _initialize(state.overview['allowedBusinesses']);
        final cities =
            _businesses
                .map((item) => _label(item, 'city'))
                .where((v) => v.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
        final categories =
            _businesses
                .map((item) => _label(item, 'category'))
                .where((v) => v.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
        final query = _searchController.text.trim().toLowerCase();
        final filtered = _businesses.where((item) {
          final name = _label(item, 'name').toLowerCase();
          return (query.isEmpty || name.contains(query)) &&
              (_city == null || _label(item, 'city') == _city) &&
              (_category == null || _label(item, 'category') == _category);
        }).toList();
        final saving = state.status == KidsStatus.actionLoading;

        return Scaffold(
          appBar: AppBar(title: const Text('Comercios permitidos')),
          body: AbsorbPointer(
            absorbing: saving,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Buscar comercio por nombre',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _city,
                        decoration: const InputDecoration(labelText: 'Ciudad'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todas'),
                          ),
                          ...cities.map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          ),
                        ],
                        onChanged: (value) => setState(() => _city = value),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todas'),
                          ),
                          ...categories.map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          ),
                        ],
                        onChanged: (value) => setState(() => _category = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Comercios aprobados',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (state.status == KidsStatus.loading)
                  const Center(child: CircularProgressIndicator())
                else if (filtered.isEmpty)
                  const CiervoEmptyState(
                    title: 'No hay comercios disponibles',
                    description: 'Prueba con otros filtros.',
                    icon: Icons.storefront_outlined,
                  )
                else
                  ...filtered.map((item) {
                    final id = _id(item);
                    return SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _label(item, 'name').isEmpty
                            ? 'Comercio'
                            : _label(item, 'name'),
                      ),
                      subtitle: Text(
                        [
                          _label(item, 'city'),
                          _label(item, 'category'),
                        ].where((v) => v.isNotEmpty).join(' · '),
                      ),
                      value: _selected.contains(id),
                      onChanged: (enabled) => setState(
                        () =>
                            enabled ? _selected.add(id) : _selected.remove(id),
                      ),
                    );
                  }),
                const SizedBox(height: AppSpacing.lg),
                CiervoButton(
                  label: saving ? 'Guardando' : 'Guardar cambios',
                  icon: Icons.save_outlined,
                  state: saving
                      ? CiervoButtonState.loading
                      : CiervoButtonState.normal,
                  onPressed: saving
                      ? null
                      : () async {
                          final saved = await context
                              .read<KidsCubit>()
                              .saveAllowedBusinesses(
                                widget.childId,
                                _selected.toList(),
                              );
                          if (saved && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
