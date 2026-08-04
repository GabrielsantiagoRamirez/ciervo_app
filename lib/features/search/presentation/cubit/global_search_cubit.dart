import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../../../core/location/location_service.dart';
import '../../domain/entities/global_search_models.dart';
import '../../domain/repositories/global_search_repository.dart';

enum GlobalSearchStatus { initial, loading, loaded, empty, failure }

class GlobalSearchState {
  const GlobalSearchState({
    this.status = GlobalSearchStatus.initial,
    this.query = '',
    this.selectedType,
    this.items = const [],
    this.counts = const GlobalSearchCounts(),
    this.total = 0,
    this.errorMessage,
    this.usingLocation = false,
  });

  final GlobalSearchStatus status;
  final String query;

  /// null = todos los tipos.
  final GlobalSearchItemType? selectedType;
  final List<GlobalSearchItem> items;
  final GlobalSearchCounts counts;
  final int total;
  final String? errorMessage;
  final bool usingLocation;

  GlobalSearchState copyWith({
    GlobalSearchStatus? status,
    String? query,
    GlobalSearchItemType? selectedType,
    bool clearSelectedType = false,
    List<GlobalSearchItem>? items,
    GlobalSearchCounts? counts,
    int? total,
    String? errorMessage,
    bool clearError = false,
    bool? usingLocation,
  }) {
    return GlobalSearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      selectedType: clearSelectedType
          ? null
          : (selectedType ?? this.selectedType),
      items: items ?? this.items,
      counts: counts ?? this.counts,
      total: total ?? this.total,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      usingLocation: usingLocation ?? this.usingLocation,
    );
  }
}

class GlobalSearchCubit extends Cubit<GlobalSearchState> {
  GlobalSearchCubit({
    required GlobalSearchRepository repository,
    required LocationService locationService,
    String? initialQuery,
  }) : _repository = repository,
       _locationService = locationService,
       super(GlobalSearchState(query: initialQuery?.trim() ?? ''));

  final GlobalSearchRepository _repository;
  final LocationService _locationService;

  Future<void> search(String query, {GlobalSearchItemType? type}) async {
    final selected = type ?? state.selectedType;
    emit(
      state.copyWith(
        status: GlobalSearchStatus.loading,
        query: query,
        selectedType: selected,
        clearSelectedType: selected == null,
        clearError: true,
      ),
    );

    final location = await _currentLocation();
    final result = await _repository.search(
      query: query,
      latitude: location?.latitude,
      longitude: location?.longitude,
      radiusKm: location == null ? null : 15,
      limit: 30,
      types: selected?.apiTypesParam,
    );

    result.when(
      success: (data) {
        final items = data.items;
        emit(
          state.copyWith(
            status: items.isEmpty
                ? GlobalSearchStatus.empty
                : GlobalSearchStatus.loaded,
            items: items,
            counts: data.counts,
            total: data.total,
            usingLocation: location != null,
            clearError: true,
          ),
        );
      },
      failure: (error) => emit(
        state.copyWith(
          status: GlobalSearchStatus.failure,
          errorMessage: UserErrorMessage.from(error),
          items: const [],
        ),
      ),
    );
  }

  Future<void> selectType(GlobalSearchItemType? type) async {
    emit(
      state.copyWith(
        selectedType: type,
        clearSelectedType: type == null,
      ),
    );
    final q = state.query.trim();
    if (q.length >= 2 || state.usingLocation) {
      await search(q, type: type);
    }
  }

  Future<void> searchNearby() async {
    emit(state.copyWith(status: GlobalSearchStatus.loading, clearError: true));
    final location = await _currentLocation();
    if (location == null) {
      emit(
        state.copyWith(
          status: GlobalSearchStatus.failure,
          errorMessage:
              'Activa la ubicación para buscar lo que hay cerca de ti.',
        ),
      );
      return;
    }

    final selected = state.selectedType;
    final result = await _repository.search(
      query: '',
      latitude: location.latitude,
      longitude: location.longitude,
      radiusKm: 5,
      limit: 20,
      types: selected?.apiTypesParam,
    );

    result.when(
      success: (data) {
        emit(
          state.copyWith(
            status: data.items.isEmpty
                ? GlobalSearchStatus.empty
                : GlobalSearchStatus.loaded,
            query: '',
            items: data.items,
            counts: data.counts,
            total: data.total,
            usingLocation: true,
            clearError: true,
          ),
        );
      },
      failure: (error) => emit(
        state.copyWith(
          status: GlobalSearchStatus.failure,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<({double latitude, double longitude})?> _currentLocation() async {
    try {
      final loc = await _locationService.currentLocation();
      return (latitude: loc.latitude, longitude: loc.longitude);
    } catch (_) {
      try {
        final last = await _locationService.lastKnownLocation();
        if (last == null) return null;
        return (latitude: last.latitude, longitude: last.longitude);
      } catch (_) {
        return null;
      }
    }
  }
}
