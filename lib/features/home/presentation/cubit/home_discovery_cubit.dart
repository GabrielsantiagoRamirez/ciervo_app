import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../../../core/experience/experience_mode.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/location/location_failure.dart';
import '../../../../core/location/location_permission_status.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/kids/selected_kid_context.dart';
import '../../../../core/di/service_locator.dart';
import '../../../discovery/domain/entities/business_summary.dart';
import '../../../discovery/domain/repositories/discovery_repository.dart';
import '../../../discovery/data/repositories/business_categories_repository.dart';
import '../../../location/data/client_location_repository.dart';
import 'home_discovery_state.dart';

class HomeDiscoveryCubit extends Cubit<HomeDiscoveryState> {
  HomeDiscoveryCubit({
    required LocationService locationService,
    required DiscoveryRepository discoveryRepository,
    required ClientLocationRepository clientLocationRepository,
    required BusinessCategoriesRepository businessCategoriesRepository,
    required ExperienceMode initialExperienceMode,
  }) : _locationService = locationService,
       _discoveryRepository = discoveryRepository,
       _clientLocationRepository = clientLocationRepository,
       _businessCategoriesRepository = businessCategoriesRepository,
       super(HomeDiscoveryState(experienceMode: initialExperienceMode));

  static const _fallbackCategories = [
    'Top',
    'bar',
    'hoteles',
    'restaurantes',
    'bares',
    'discotecas',
    'licorerias',
    'farmacias',
    'turismo',
    'transporte',
  ];

  List<String> get categories =>
      state.categories.isEmpty ? _fallbackCategories : state.categories;

  final LocationService _locationService;
  final DiscoveryRepository _discoveryRepository;
  final ClientLocationRepository _clientLocationRepository;
  final BusinessCategoriesRepository _businessCategoriesRepository;

  Future<void> initialize() async {
    await loadCategories();

    final permission = await _locationService.permissionStatus();
    emit(state.copyWith(permissionStatus: permission));

    if (permission == AppLocationPermissionStatus.granted) {
      await loadNearby();
      return;
    }

    await loadGeneral();
  }

  Future<void> loadCategories() async {
    final result = await _businessCategoriesRepository.all();
    result.when(
      success: (items) {
        final values = [
          'Top',
          ...items.map(
            (item) => item.code.isNotEmpty ? item.code : item.id.toString(),
          ),
        ];
        emit(state.copyWith(categories: values));
      },
      failure: (_) {
        if (state.categories.isEmpty) {
          emit(state.copyWith(categories: _fallbackCategories));
        }
      },
    );
  }

  Future<void> requestLocation() async {
    final permission = await _locationService.requestPermission();
    emit(state.copyWith(permissionStatus: permission));

    if (permission == AppLocationPermissionStatus.granted) {
      await loadNearby();
      return;
    }

    await loadGeneral();
  }

  Future<void> loadNearby() async {
    emit(state.copyWith(status: HomeDiscoveryStatus.loading, clearError: true));

    try {
      final syncedLocation = await _clientLocationRepository.syncForRecommendations(
        city: state.city,
        countryCode: state.countryCode,
      );
      final location = syncedLocation.when(
        success: (value) => value,
        failure: (_) => null,
      ) ?? await _currentOrLastKnownLocation();
      final result = await _discoveryRepository.nearbyBusinesses(
        location: location,
        experienceMode: state.experienceMode,
        countryCode: state.countryCode,
        city: state.city,
        category: state.selectedCategory,
        kidId: getIt<SelectedKidContext>().kidId,
      );
      result.when(
        success: (businesses) => emit(
          state.copyWith(
            status: businesses.isEmpty
                ? HomeDiscoveryStatus.empty
                : HomeDiscoveryStatus.loaded,
            businesses: _closestFirst(businesses),
            usingLocation: true,
            location: location,
          ),
        ),
        failure: (error) => emit(
          state.copyWith(
            status: HomeDiscoveryStatus.failure,
            errorMessage: UserErrorMessage.from(error),
            usingLocation: false,
          ),
        ),
      );
    } on LocationFailure catch (error) {
      emit(
        state.copyWith(
          permissionStatus: switch (error.type) {
            LocationFailureType.serviceDisabled =>
              AppLocationPermissionStatus.serviceDisabled,
            LocationFailureType.denied => AppLocationPermissionStatus.denied,
            LocationFailureType.deniedForever =>
              AppLocationPermissionStatus.deniedForever,
            _ => state.permissionStatus,
          },
          errorMessage: error.message,
          usingLocation: false,
        ),
      );
      await loadGeneral();
    }
  }

  Future<void> loadGeneral() async {
    emit(
      state.copyWith(
        status: HomeDiscoveryStatus.loading,
        clearError: true,
        usingLocation: false,
      ),
    );

    final result = state.selectedCategory == 'Top'
        ? await _discoveryRepository.businessesByCity(
            state.city,
            location: state.location,
            experienceMode: state.experienceMode,
            countryCode: state.countryCode,
            kidId: getIt<SelectedKidContext>().kidId,
          )
        : await _discoveryRepository.businessesByCategory(
            state.selectedCategory,
            location: state.location,
            experienceMode: state.experienceMode,
            countryCode: state.countryCode,
            city: state.city,
            kidId: getIt<SelectedKidContext>().kidId,
          );

    result.when(
      success: (businesses) => emit(
        state.copyWith(
          status: businesses.isEmpty
              ? HomeDiscoveryStatus.empty
              : HomeDiscoveryStatus.loaded,
          businesses: _closestFirst(businesses),
          usingLocation: false,
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          status: HomeDiscoveryStatus.failure,
          errorMessage: UserErrorMessage.from(error),
          usingLocation: false,
        ),
      ),
    );
  }

  Future<void> selectCategory(String category) async {
    emit(state.copyWith(selectedCategory: category));
    if (state.permissionStatus == AppLocationPermissionStatus.granted) {
      await loadNearby();
      return;
    }
    await loadGeneral();
  }

  Future<void> search(String query, {String? category}) async {
    if (query.trim().isEmpty) {
      if (category != null && category != 'Top') {
        emit(state.copyWith(selectedCategory: category));
        await loadGeneral();
        return;
      }
      await initialize();
      return;
    }

    emit(state.copyWith(status: HomeDiscoveryStatus.loading, clearError: true));
    final location = state.location ?? await _currentOrNullLocation();
    final selectedCategory = category ?? state.selectedCategory;
    final result = await _discoveryRepository.searchBusinesses(
      query,
      location: location,
      experienceMode: state.experienceMode,
      countryCode: state.countryCode,
      city: state.city,
      category: selectedCategory == 'Top' ? null : selectedCategory,
      kidId: getIt<SelectedKidContext>().kidId,
    );
    result.when(
      success: (businesses) => emit(
        state.copyWith(
          status: businesses.isEmpty
              ? HomeDiscoveryStatus.empty
              : HomeDiscoveryStatus.loaded,
          businesses: _closestFirst(businesses),
          usingLocation: location != null,
          location: location,
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          status: HomeDiscoveryStatus.failure,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> openAppSettings() => _locationService.openAppSettings();

  Future<void> openLocationSettings() =>
      _locationService.openLocationSettings();

  Future<void> setExperienceMode(
    ExperienceMode mode, {
    bool reload = true,
  }) async {
    emit(state.copyWith(
      experienceMode: mode,
      selectedCategory: categories.contains(state.selectedCategory)
          ? state.selectedCategory
          : 'Top',
    ));
    if (!reload) {
      return;
    }
    if (state.permissionStatus == AppLocationPermissionStatus.granted) {
      await loadNearby();
      return;
    }
    await loadGeneral();
  }

  Future<void> setCountry({
    required String countryCode,
    required String city,
  }) async {
    emit(state.copyWith(countryCode: countryCode, city: city));
    await loadGeneral();
  }

  Future<AppLocation> _currentOrLastKnownLocation() async {
    try {
      return await _locationService.currentLocation();
    } on LocationFailure {
      final last = await _locationService.lastKnownLocation();
      if (last != null) {
        return last;
      }
      rethrow;
    }
  }

  Future<AppLocation?> _currentOrNullLocation() async {
    try {
      return await _currentOrLastKnownLocation();
    } catch (_) {
      return state.location;
    }
  }

  List<BusinessSummary> _closestFirst(List<BusinessSummary> businesses) {
    final sorted = [...businesses];
    sorted.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return sorted;
  }
}
