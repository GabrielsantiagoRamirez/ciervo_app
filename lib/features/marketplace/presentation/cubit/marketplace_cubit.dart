import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../../../core/location/location_service.dart';
import '../../domain/entities/marketplace_models.dart';
import '../../domain/repositories/marketplace_repository.dart';

enum MarketplaceStatus { initial, loading, loaded, empty, failure }

class MarketplaceState {
  const MarketplaceState({
    this.status = MarketplaceStatus.initial,
    this.items = const [],
    this.highlights = const [],
    this.popular = const [],
    this.cashback = const [],
    this.points = const [],
    this.nearby = const [],
    this.filtersCatalog = const MarketplaceFiltersCatalog(),
    this.query = const MarketplaceFeedQuery(),
    this.errorMessage,
    this.hasMore = false,
    this.loadingMore = false,
  });

  final MarketplaceStatus status;
  final List<MarketplacePromo> items;
  final List<MarketplacePromo> highlights;
  final List<MarketplacePromo> popular;
  final List<MarketplacePromo> cashback;
  final List<MarketplacePromo> points;
  final List<MarketplacePromo> nearby;
  final MarketplaceFiltersCatalog filtersCatalog;
  final MarketplaceFeedQuery query;
  final String? errorMessage;
  final bool hasMore;
  final bool loadingMore;

  MarketplaceState copyWith({
    MarketplaceStatus? status,
    List<MarketplacePromo>? items,
    List<MarketplacePromo>? highlights,
    List<MarketplacePromo>? popular,
    List<MarketplacePromo>? cashback,
    List<MarketplacePromo>? points,
    List<MarketplacePromo>? nearby,
    MarketplaceFiltersCatalog? filtersCatalog,
    MarketplaceFeedQuery? query,
    String? errorMessage,
    bool clearError = false,
    bool? hasMore,
    bool? loadingMore,
  }) => MarketplaceState(
    status: status ?? this.status,
    items: items ?? this.items,
    highlights: highlights ?? this.highlights,
    popular: popular ?? this.popular,
    cashback: cashback ?? this.cashback,
    points: points ?? this.points,
    nearby: nearby ?? this.nearby,
    filtersCatalog: filtersCatalog ?? this.filtersCatalog,
    query: query ?? this.query,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

class MarketplaceCubit extends Cubit<MarketplaceState> {
  MarketplaceCubit({
    required MarketplaceRepository repository,
    required LocationService locationService,
  }) : _repository = repository,
       _locationService = locationService,
       super(const MarketplaceState());

  final MarketplaceRepository _repository;
  final LocationService _locationService;

  Future<void> initialize() async {
    emit(state.copyWith(status: MarketplaceStatus.loading, clearError: true));
    final filtersResult = await _repository.filters();
    filtersResult.when(
      success: (catalog) => emit(state.copyWith(filtersCatalog: catalog)),
      failure: (_) {},
    );
    await Future.wait([_loadSections(), refreshFeed(reset: true)]);
  }

  Future<void> refreshFeed({bool reset = false}) async {
    final query = reset ? state.query.copyWith(page: 1) : state.query;
    if (reset) {
      emit(
        state.copyWith(
          status: MarketplaceStatus.loading,
          query: query,
          clearError: true,
        ),
      );
    }

    final search = query.buscar?.trim();
    if (search != null && search.isNotEmpty) {
      final result = await _repository.search(search, limit: query.limit);
      result.when(
        success: (items) => emit(
          state.copyWith(
            status: items.isEmpty
                ? MarketplaceStatus.empty
                : MarketplaceStatus.loaded,
            items: items,
            query: query,
            hasMore: false,
          ),
        ),
        failure: (error) => emit(
          state.copyWith(
            status: MarketplaceStatus.failure,
            errorMessage: UserErrorMessage.from(error),
          ),
        ),
      );
      return;
    }

    final result = await _repository.feed(query);
    result.when(
      success: (page) {
        final items = reset ? page.items : [...state.items, ...page.items];
        emit(
          state.copyWith(
            status: items.isEmpty
                ? MarketplaceStatus.empty
                : MarketplaceStatus.loaded,
            items: items,
            query: query.copyWith(page: page.page),
            hasMore: page.hasMore,
            loadingMore: false,
          ),
        );
      },
      failure: (error) => emit(
        state.copyWith(
          status: MarketplaceStatus.failure,
          errorMessage: UserErrorMessage.from(error),
          loadingMore: false,
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true));
    final next = state.query.copyWith(page: state.query.page + 1);
    emit(state.copyWith(query: next));
    await refreshFeed();
  }

  Future<void> applyQuery(MarketplaceFeedQuery query) async {
    emit(state.copyWith(query: query.copyWith(page: 1)));
    await refreshFeed(reset: true);
  }

  Future<void> search(String text) async {
    await applyQuery(state.query.copyWith(buscar: text, page: 1));
  }

  Future<void> clearFilters() async {
    await applyQuery(const MarketplaceFeedQuery());
  }

  Future<void> toggleFavorite(MarketplacePromo promo) async {
    final result = promo.isFavorite
        ? await _repository.removeFavorite(promo.id)
        : await _repository.addFavorite(promo.id);
    result.when(
      success: (_) {
        final updated = promo.copyWith(isFavorite: !promo.isFavorite);
        emit(
          state.copyWith(
            items: _replace(state.items, updated),
            highlights: _replace(state.highlights, updated),
            popular: _replace(state.popular, updated),
            cashback: _replace(state.cashback, updated),
            points: _replace(state.points, updated),
            nearby: _replace(state.nearby, updated),
          ),
        );
      },
      failure: (_) {},
    );
  }

  Future<void> _loadSections() async {
    final highlights = await _repository.highlights(limit: 12);
    final popular = await _repository.popular(limit: 12);
    final cashback = await _repository.cashbackPromos(limit: 12);
    final points = await _repository.pointsPromos(limit: 12);

    var nearby = const <MarketplacePromo>[];
    try {
      final location = await _locationService.currentLocation();
      final nearbyResult = await _repository.nearby(
        lat: location.latitude,
        lng: location.longitude,
        radio: 15,
        limit: 12,
      );
      nearbyResult.when(success: (items) => nearby = items, failure: (_) {});
    } catch (_) {}

    emit(
      state.copyWith(
        highlights: highlights.when(
          success: (v) => v,
          failure: (_) => const [],
        ),
        popular: popular.when(success: (v) => v, failure: (_) => const []),
        cashback: cashback.when(success: (v) => v, failure: (_) => const []),
        points: points.when(success: (v) => v, failure: (_) => const []),
        nearby: nearby,
      ),
    );
  }

  List<MarketplacePromo> _replace(
    List<MarketplacePromo> source,
    MarketplacePromo updated,
  ) => source
      .map((item) => item.id == updated.id ? updated : item)
      .toList(growable: false);
}
