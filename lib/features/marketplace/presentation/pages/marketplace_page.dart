import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../domain/entities/marketplace_models.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../cubit/marketplace_cubit.dart';
import '../widgets/marketplace_filters_sheet.dart';
import '../widgets/marketplace_promo_card.dart';

class MarketplacePage extends StatelessWidget {
  const MarketplacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MarketplaceCubit(
        repository: getIt<MarketplaceRepository>(),
        locationService: getIt<LocationService>(),
      )..initialize(),
      child: const _MarketplaceView(),
    );
  }
}

class _MarketplaceView extends StatefulWidget {
  const _MarketplaceView();

  @override
  State<_MarketplaceView> createState() => _MarketplaceViewState();
}

class _MarketplaceViewState extends State<_MarketplaceView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (_scrollController.position.pixels > max - 400) {
      context.read<MarketplaceCubit>().loadMore();
    }
  }

  Future<void> _openFilters() async {
    final cubit = context.read<MarketplaceCubit>();
    final applied = await showMarketplaceFiltersSheet(
      context: context,
      initial: cubit.state.query,
      catalog: cubit.state.filtersCatalog,
    );
    if (applied != null && mounted) {
      await cubit.applyQuery(applied);
    }
  }

  void _openPromo(MarketplacePromo promo) {
    context.push('/marketplace/promos/${promo.id}');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900 ? 3 : (width >= 600 ? 2 : 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            tooltip: 'Escanear comercio',
            onPressed: () => context.push('/marketplace/scan'),
            icon: const Icon(Icons.qr_code_scanner_outlined),
          ),
          IconButton(
            tooltip: 'Mis pedidos',
            onPressed: () => context.push('/marketplace/orders'),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          IconButton(
            tooltip: 'Filtros',
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible:
                  context.watch<MarketplaceCubit>().state.query.activeCount > 0,
              label: Text(
                '${context.watch<MarketplaceCubit>().state.query.activeCount}',
              ),
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
      body: BlocBuilder<MarketplaceCubit, MarketplaceState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<MarketplaceCubit>().initialize(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Builder(
                      builder: (context) {
                        final scheme = Theme.of(context).colorScheme;
                        return TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          style: TextStyle(color: scheme.onSurface),
                          cursorColor: scheme.primary,
                          onSubmitted: (value) =>
                              context.read<MarketplaceCubit>().search(value),
                          decoration: InputDecoration(
                            hintText: 'Buscar promos, comercios…',
                            hintStyle: TextStyle(
                              color: scheme.onSurfaceVariant,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: scheme.onSurfaceVariant,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                final value = _searchController.text.trim();
                                context.read<MarketplaceCubit>().search(value);
                              },
                              icon: Icon(
                                Icons.arrow_forward,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            filled: true,
                            fillColor: scheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: scheme.primary.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (state.highlights.isNotEmpty)
                  _HorizontalSection(
                    title: 'Destacadas',
                    items: state.highlights,
                    onTap: _openPromo,
                    onFavorite: (promo) =>
                        context.read<MarketplaceCubit>().toggleFavorite(promo),
                  ),
                if (state.nearby.isNotEmpty)
                  _HorizontalSection(
                    title: 'Cerca de ti',
                    items: state.nearby,
                    onTap: _openPromo,
                    onFavorite: (promo) =>
                        context.read<MarketplaceCubit>().toggleFavorite(promo),
                  ),
                if (state.cashback.isNotEmpty)
                  _HorizontalSection(
                    title: 'Cashback',
                    items: state.cashback,
                    onTap: _openPromo,
                    onFavorite: (promo) =>
                        context.read<MarketplaceCubit>().toggleFavorite(promo),
                  ),
                if (state.points.isNotEmpty)
                  _HorizontalSection(
                    title: 'Puntos',
                    items: state.points,
                    onTap: _openPromo,
                    onFavorite: (promo) =>
                        context.read<MarketplaceCubit>().toggleFavorite(promo),
                  ),
                if (state.popular.isNotEmpty)
                  _HorizontalSection(
                    title: 'Populares',
                    items: state.popular,
                    onTap: _openPromo,
                    onFavorite: (promo) =>
                        context.read<MarketplaceCubit>().toggleFavorite(promo),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Text(
                      'Todas las ofertas',
                      style: AppTextStyles.title,
                    ),
                  ),
                ),
                if (state.status == MarketplaceStatus.loading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CiervoLoadingState(itemCount: 4),
                    ),
                  )
                else if (state.status == MarketplaceStatus.failure)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: CiervoErrorState(
                        title: 'No pudimos cargar el marketplace',
                        description: state.errorMessage ?? 'Intenta de nuevo.',
                        onRetry: () =>
                            context.read<MarketplaceCubit>().initialize(),
                      ),
                    ),
                  )
                else if (state.status == MarketplaceStatus.empty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: CiervoEmptyState(
                        title: 'Sin resultados',
                        description:
                            'Prueba otra búsqueda o limpia los filtros.',
                        icon: Icons.storefront_outlined,
                        actionLabel: 'Limpiar filtros',
                        onAction: () =>
                            context.read<MarketplaceCubit>().clearFilters(),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: crossAxisCount == 1 ? 1.35 : 0.78,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= state.items.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final promo = state.items[index];
                          return MarketplacePromoCard(
                            promo: promo,
                            onTap: () => _openPromo(promo),
                            onFavorite: () => context
                                .read<MarketplaceCubit>()
                                .toggleFavorite(promo),
                          );
                        },
                        childCount:
                            state.items.length + (state.loadingMore ? 1 : 0),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HorizontalSection extends StatelessWidget {
  const _HorizontalSection({
    required this.title,
    required this.items,
    required this.onTap,
    required this.onFavorite,
  });

  final String title;
  final List<MarketplacePromo> items;
  final ValueChanged<MarketplacePromo> onTap;
  final ValueChanged<MarketplacePromo> onFavorite;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              title,
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
          ),
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final promo = items[index];
                return MarketplacePromoCard(
                  promo: promo,
                  horizontal: true,
                  onTap: () => onTap(promo),
                  onFavorite: () => onFavorite(promo),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
