import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/experience/experience_mode_cubit.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/ciervo_empty_state.dart';
import '../../../../shared/widgets/ciervo_error_state.dart';
import '../../../../shared/widgets/ciervo_loading_state.dart';
import '../../../discovery/data/repositories/business_categories_repository.dart';
import '../../../home/domain/entities/home_place.dart';
import '../../../home/presentation/widgets/home_place_card.dart';
import '../../../place_detail/presentation/pages/place_detail_page.dart';
import '../../domain/entities/favorite_business.dart';
import '../../domain/entities/favorite_filters.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../widgets/favorite_counts_badge.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _scrollController = ScrollController();
  final _items = <FavoriteBusiness>[];
  var _page = 1;
  var _loading = true;
  var _loadingMore = false;
  var _hasMore = true;
  String? _error;

  FavoriteFilters _filters = const FavoriteFilters();
  List<Map<String, dynamic>> _categories = const [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _load(reset: true);
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_maybeLoadMore)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final result = await getIt<BusinessCategoriesRepository>().all();
    result.when(
      success: (categories) {
        if (!mounted) return;
        setState(() {
          _categories = categories
              .map((c) => {'id': c.id, 'name': c.name})
              .toList();
        });
      },
      failure: (_) {},
    );
  }

  void _maybeLoadMore() {
    if (!_hasMore || _loading || _loadingMore) return;
    if (_scrollController.position.extentAfter < 420) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _page = 1;
        _hasMore = true;
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    double? lat = _filters.nearLat;
    double? lng = _filters.nearLng;
    if (lat == null || lng == null) {
      try {
      final location = await getIt<LocationService>().currentLocation();
      lat = location.latitude;
      lng = location.longitude;
      } catch (_) {}
    }

    final filters = _filters.copyWith(
      page: _page,
      nearLat: lat,
      nearLng: lng,
      radiusKm: _filters.radiusKm ?? (lat == null ? null : 25),
    );

    final result = await getIt<FavoritesRepository>().list(filters);
    if (!mounted) return;
    result.when(
      success: (items) {
        setState(() {
          if (reset) _items.clear();
          _items.addAll(_dedupe(items));
          _hasMore = items.length >= filters.pageSize;
          _page += 1;
          _loading = false;
          _loadingMore = false;
        });
      },
      failure: (error) {
        setState(() {
          _error = UserErrorMessage.from(error);
          _loading = false;
          _loadingMore = false;
        });
      },
    );
  }

  List<FavoriteBusiness> _dedupe(List<FavoriteBusiness> incoming) {
    final existing = _items.map((item) => item.businessId).toSet();
    return incoming.where((item) => existing.add(item.businessId)).toList();
  }

  Future<void> _openFilters() async {
    final countryController = TextEditingController(text: _filters.country ?? '');
    final cityController = TextEditingController(text: _filters.city ?? '');
    final zoneController = TextEditingController(text: _filters.zone ?? '');
    final radiusController = TextEditingController(
      text: _filters.radiusKm?.toString() ?? '',
    );
    var sortBy = _filters.sortBy;
    int? categoryId = _filters.categoryId;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filtrar favoritos', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: countryController,
                decoration: const InputDecoration(labelText: 'Pais (CO, CL...)'),
              ),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'Ciudad'),
              ),
              TextField(
                controller: zoneController,
                decoration: const InputDecoration(labelText: 'Zona'),
              ),
              TextField(
                controller: radiusController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Radio km'),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<int?>(
                value: categoryId,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
                  ..._categories.map(
                    (c) => DropdownMenuItem<int?>(
                      value: c['id'] as int,
                      child: Text('${c['name']}'),
                    ),
                  ),
                ],
                onChanged: (value) => setModalState(() => categoryId = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<FavoriteSortBy>(
                value: sortBy,
                decoration: const InputDecoration(labelText: 'Ordenar por'),
                items: FavoriteSortBy.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setModalState(() => sortBy = value);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Aplicar'),
              ),
            ],
          ),
        ),
      ),
    );

    if (applied != true || !mounted) return;
    setState(() {
      _filters = FavoriteFilters(
        country: _emptyToNull(countryController.text),
        city: _emptyToNull(cityController.text),
        zone: _emptyToNull(zoneController.text),
        categoryId: categoryId,
        radiusKm: double.tryParse(radiusController.text.trim()),
        sortBy: sortBy,
      );
    });
    await _load(reset: true);
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Mis favoritos'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filtros',
              onPressed: _openFilters,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => _load(reset: true),
          color: AppColors.primary,
          child: _body(),
        ),
      );

  Widget _body() {
    if (_loading) return const CiervoLoadingState(itemCount: 4);
    if (_error != null && _items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          CiervoErrorState(
            title: 'No pudimos cargar tus favoritos',
            description: _error!,
            onRetry: () => _load(reset: true),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          CiervoEmptyState(
            title: 'Sin favoritos',
            description: 'Guarda comercios para encontrarlos rapido despues.',
            icon: Icons.favorite_border,
          ),
        ],
      );
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _items.length + (_loadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final favorite = _items[index];
        final place = _placeFrom(favorite);
        return Stack(
          children: [
            HomePlaceCard(
              place: place,
              mode: context.watch<ExperienceModeCubit>().state.mode,
              isFavorite: true,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PlaceDetailPage(place: place),
                  ),
                );
                if (mounted) _load(reset: true);
              },
            ),
            Positioned(
              right: AppSpacing.sm,
              bottom: 48,
              child: FavoriteCountsBadge(
                bonuses: favorite.activeBonusesCount,
                campaigns: favorite.activeCampaignsCount,
              ),
            ),
          ],
        );
      },
    );
  }

  HomePlace _placeFrom(FavoriteBusiness favorite) => HomePlace(
        id: favorite.businessId,
        name: favorite.name,
        category: favorite.category,
        rating: favorite.rating,
        priceLevel: favorite.priceLevel,
        distanceKm: favorite.distanceKm,
        matchPercent: 0,
        imageUrl: favorite.imageUrl,
        businessCategoryId: favorite.businessCategoryId,
        isFavorite: true,
        city: favorite.city,
        countryCode: favorite.country,
      );
}
