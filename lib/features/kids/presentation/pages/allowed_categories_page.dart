import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_button.dart';
import '../../domain/repositories/kids_repository.dart';
import '../cubit/kids_cubit.dart';
import '../cubit/kids_state.dart';

class AllowedCategoriesPage extends StatelessWidget {
  const AllowedCategoriesPage({required this.childId, super.key});
  final String childId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        KidsCubit(getIt<KidsRepository>())..loadAllowedCategories(childId),
    child: _CategoriesView(childId: childId),
  );
}

class _CategoriesView extends StatefulWidget {
  const _CategoriesView({required this.childId});
  final String childId;
  @override
  State<_CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<_CategoriesView> {
  final Set<int> _selected = {};
  bool _initialized = false;

  @override
  Widget build(BuildContext context) => BlocConsumer<KidsCubit, KidsState>(
    listener: (context, state) {
      if (state.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      }
    },
    builder: (context, state) {
      final raw = state.overview['allowedCategories'];
      final categories = raw is List
          ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : <Map<String, dynamic>>[];
      if (!_initialized && categories.isNotEmpty) {
        _selected.addAll(
          categories
              .where((e) => e['isAllowed'] != false)
              .map((e) => int.tryParse('${e['categoryId'] ?? e['id']}'))
              .whereType<int>(),
        );
        _initialized = true;
      }
      final saving = state.status == KidsStatus.actionLoading;
      return Scaffold(
        appBar: AppBar(title: const Text('Categorias permitidas')),
        body: AbsorbPointer(
          absorbing: saving,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (state.status == KidsStatus.loading)
                const Center(child: CircularProgressIndicator())
              else
                ...categories.map((category) {
                  final id = int.tryParse(
                    '${category['categoryId'] ?? category['id']}',
                  );
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${category['name'] ?? category['displayName'] ?? 'Categoria'}',
                    ),
                    value: id != null && _selected.contains(id),
                    onChanged: id == null
                        ? null
                        : (checked) => setState(
                            () => checked == true
                                ? _selected.add(id)
                                : _selected.remove(id),
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
                            .saveAllowedCategories(
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
