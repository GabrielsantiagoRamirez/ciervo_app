import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/entities/global_search_models.dart';
import '../../domain/repositories/global_search_repository.dart';
import '../cubit/global_search_cubit.dart';
import '../global_search_navigation.dart';

/// Buscador unificado: GET /api/search (personas, lugares, productos, etc.).
class SearchPage extends StatelessWidget {
  const SearchPage({this.initialQuery, super.key});

  final String? initialQuery;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = GlobalSearchCubit(
          repository: getIt<GlobalSearchRepository>(),
          locationService: getIt<LocationService>(),
          initialQuery: initialQuery,
        );
        final q = initialQuery?.trim() ?? '';
        if (q.length >= 2) {
          cubit.search(q);
        }
        return cubit;
      },
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<GlobalSearchCubit>().state.query,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<GlobalSearchCubit>().search(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GlobalSearchCubit>().state;
    final cubit = context.read<GlobalSearchCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText:
                        'Personas, lugares, productos, promos, servicios…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              setState(() {});
                            },
                          ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    FilterChip(
                      label: Text(
                        state.counts.total > 0
                            ? 'Todo (${state.total})'
                            : 'Todo',
                      ),
                      selected: state.selectedType == null,
                      onSelected: (_) => cubit.selectType(null),
                    ),
                    for (final type in const [
                      GlobalSearchItemType.person,
                      GlobalSearchItemType.business,
                      GlobalSearchItemType.product,
                      GlobalSearchItemType.promotion,
                      GlobalSearchItemType.service,
                      GlobalSearchItemType.event,
                    ])
                      FilterChip(
                        avatar: Icon(iconForSearchType(type), size: 16),
                        label: Text(
                          state.counts.forType(type) > 0
                              ? '${type.chipLabel} (${state.counts.forType(type)})'
                              : type.chipLabel,
                        ),
                        selected: state.selectedType == type,
                        onSelected: (_) => cubit.selectType(type),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: cubit.searchNearby,
                        icon: const Icon(Icons.near_me_outlined),
                        label: const Text('Cerca de mí'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      onPressed: _submit,
                      child: const Text('Buscar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _ResultsBody(state: state)),
        ],
      ),
    );
  }
}

class _ResultsBody extends StatelessWidget {
  const _ResultsBody({required this.state});

  final GlobalSearchState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      GlobalSearchStatus.initial => const CiervoEmptyState(
        title: '¿Qué estás buscando?',
        description:
            'Personas, comercios, comida, promos, servicios o eventos cerca de ti.',
        icon: Icons.search_rounded,
      ),
      GlobalSearchStatus.loading => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: CiervoLoadingState(itemCount: 6),
      ),
      GlobalSearchStatus.failure => CiervoErrorState(
        title: 'No pudimos buscar',
        description: state.errorMessage ?? 'Intenta de nuevo.',
        onRetry: () => context.read<GlobalSearchCubit>().search(state.query),
      ),
      GlobalSearchStatus.empty => CiervoEmptyState(
        title: 'Sin resultados',
        description: state.query.isEmpty
            ? 'No hay resultados cerca en este momento.'
            : 'Nada coincide con “${state.query}”. Prueba otro término o filtro.',
        icon: Icons.search_off_outlined,
      ),
      GlobalSearchStatus.loaded => ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        itemCount: state.items.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final item = state.items[index];
          return _SearchResultTile(item: item);
        },
      ),
    };
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.item});

  final GlobalSearchItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = [
      item.type.chipLabel,
      if (item.subtitle != null && item.subtitle!.isNotEmpty) item.subtitle!,
      if (item.businessName != null &&
          item.businessName!.isNotEmpty &&
          item.businessName != item.title)
        item.businessName!,
      if (item.username != null && item.username!.isNotEmpty)
        '@${item.username}',
      if (item.ciervoUserCode != null && item.ciervoUserCode!.isNotEmpty)
        item.ciervoUserCode!,
      if (item.priceLabel.isNotEmpty) item.priceLabel,
      if (item.distanceLabel.isNotEmpty) item.distanceLabel,
    ].join(' · ');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        backgroundImage: item.imageUrl != null && item.imageUrl!.isNotEmpty
            ? NetworkImage(item.imageUrl!)
            : null,
        child: item.imageUrl == null || item.imageUrl!.isEmpty
            ? Icon(iconForSearchType(item.type))
            : null,
      ),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(
        secondary,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => GlobalSearchNavigation.open(context, item),
    );
  }
}
