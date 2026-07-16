import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/country/country_registration.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/experience/experience_mode.dart';
import '../../../../core/geo/geo_repository.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/location/location_failure.dart';
import '../../../../core/location/location_permission_status.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/kids/selected_kid_context.dart';
import '../../../../core/di/service_locator.dart';
import '../../../discovery/domain/entities/business_summary.dart';
import '../../../discovery/domain/entities/discovery_smart_filters.dart';
import '../../../discovery/domain/repositories/discovery_repository.dart';
import '../../../discovery/data/repositories/business_categories_repository.dart';
import '../../../location/data/client_location_repository.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import 'home_discovery_state.dart';

class HomeDiscoveryCubit extends Cubit<HomeDiscoveryState> {
  HomeDiscoveryCubit({
    required LocationService locationService,
    required DiscoveryRepository discoveryRepository,
    required ClientLocationRepository clientLocationRepository,
    required BusinessCategoriesRepository businessCategoriesRepository,
    required GeoRepository geoRepository,
    required ProfileRepository profileRepository,
    required ExperienceMode initialExperienceMode,
  }) : _locationService = locationService,
       _discoveryRepository = discoveryRepository,
       _clientLocationRepository = clientLocationRepository,
       _businessCategoriesRepository = businessCategoriesRepository,
       _geoRepository = geoRepository,
       _profileRepository = profileRepository,
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
  final GeoRepository _geoRepository;
  final ProfileRepository _profileRepository;

  Future<void> initialize() async {
    await Future.wait([loadCategories(), _seedFromProfile()]);

    final permission = await _locationService.permissionStatus();
    emit(state.copyWith(permissionStatus: permission));

    if (permission == AppLocationPermissionStatus.granted) {
      await loadNearby();
      return;
    }

    await _tryResolveFromLastKnown();
    await loadGeneral();
  }

  Future<void> _seedFromProfile() async {
    final result = await _profileRepository.getMe();
    result.when(
      success: (profile) {
        final code = (profile.countryCode ?? '').trim().toUpperCase();
        final city = (profile.city ?? '').trim();
        if (code.isEmpty && city.isEmpty) return;
        emit(
          state.copyWith(
            countryCode: code.isNotEmpty ? code : state.countryCode,
            city: city.isNotEmpty
                ? city
                : CountryRegistration.contextForCode(
                    code.isNotEmpty ? code : state.countryCode,
                  ).city,
          ),
        );
      },
      failure: (_) {},
    );
  }

  Future<void> loadCategories() async {
    final result = await _businessCategoriesRepository.all(
      experienceMode: state.experienceMode,
    );
    result.when(
      success: (items) {
        final values = [
          'Top',
          ...items.map(
            (item) => item.code.isNotEmpty ? item.code : item.id.toString(),
          ),
        ];
        final selected = values.contains(state.selectedCategory)
            ? state.selectedCategory
            : 'Top';
        emit(state.copyWith(categories: values, selectedCategory: selected));
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
      final location = await _currentOrLastKnownLocation();
      final resolved = await _applyResolvedPlace(location);

      if (resolved) {
        await _clientLocationRepository.syncForRecommendations(
          city: state.city,
          countryCode: state.countryCode,
        );
      }

      final result = await _discoveryRepository.nearbyBusinesses(
        location: location,
        experienceMode: state.experienceMode,
        countryCode: state.countryCode,
        city: state.city,
        category: state.selectedCategory,
        kidId: getIt<SelectedKidContext>().kidId,
        filters: state.filters,
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
            filters: state.filters,
          )
        : await _discoveryRepository.businessesByCategory(
            state.selectedCategory,
            location: state.location,
            experienceMode: state.experienceMode,
            countryCode: state.countryCode,
            city: state.city,
            kidId: getIt<SelectedKidContext>().kidId,
            filters: state.filters,
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
    if (location != null) {
      await _applyResolvedPlace(location);
    }
    final selectedCategory = category ?? state.selectedCategory;
    final result = await _discoveryRepository.searchBusinesses(
      query,
      location: location,
      experienceMode: state.experienceMode,
      countryCode: state.countryCode,
      city: state.city,
      category: selectedCategory == 'Top' ? null : selectedCategory,
      kidId: getIt<SelectedKidContext>().kidId,
      filters: state.filters,
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

  Future<void> applyFilters(DiscoverySmartFilters filters) async {
    emit(state.copyWith(filters: filters));
    await _reloadResults();
  }

  Future<void> expandRadius() async {
    await applyFilters(state.filters.withExpandedRadius());
  }

  Future<void> openAppSettings() => _locationService.openAppSettings();

  Future<void> openLocationSettings() =>
      _locationService.openLocationSettings();

  Future<void> setExperienceMode(
    ExperienceMode mode, {
    bool reload = true,
  }) async {
    if (state.experienceMode == mode) {
      return;
    }
    emit(
      state.copyWith(
        experienceMode: mode,
        selectedCategory: 'Top',
      ),
    );
    if (!reload) {
      return;
    }
    await loadCategories();
    await _reloadResults();
  }

  Future<void> setCountry({
    required String countryCode,
    required String city,
  }) async {
    emit(state.copyWith(countryCode: countryCode, city: city));
    await loadGeneral();
  }

  Future<void> _reloadResults() async {
    if (state.permissionStatus == AppLocationPermissionStatus.granted) {
      await loadNearby();
      return;
    }
    await loadGeneral();
  }

  Future<void> _tryResolveFromLastKnown() async {
    try {
      final last = await _locationService.lastKnownLocation();
      if (last != null) {
        await _applyResolvedPlace(last);
      }
    } catch (_) {}
  }

  /// Resuelve país/ciudad desde GPS. Devuelve true si pudo resolver país real.
  Future<bool> _applyResolvedPlace(AppLocation location) async {
    final result = await _geoRepository.reverse(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    String? code;
    String? city;

    result.when(
      success: (geo) {
        code = CountryRegistration.resolveCountryCodeFromGeo(
          country: geo.country,
          city: geo.city,
        );
        if ((geo.city?.trim().isNotEmpty ?? false)) {
          city = geo.city!.trim();
        }
      },
      failure: (_) {},
    );

    code ??= CountryRegistration.inferCountryCodeFromCoordinates(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    if (code == null) {
      emit(state.copyWith(location: location));
      return false;
    }

    final resolvedCity = (city != null && city!.isNotEmpty)
        ? city!
        : CountryRegistration.contextForCode(code!).city;

    emit(
      state.copyWith(
        countryCode: code,
        city: resolvedCity,
        location: location,
      ),
    );
    return true;
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
