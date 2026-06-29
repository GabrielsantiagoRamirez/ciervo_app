import '../../../../core/location/location_permission_status.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/experience/experience_mode.dart';
import '../../../discovery/domain/entities/business_summary.dart';

enum HomeDiscoveryStatus { initial, loading, loaded, empty, failure }

class HomeDiscoveryState {
  const HomeDiscoveryState({
    this.status = HomeDiscoveryStatus.initial,
    this.permissionStatus = AppLocationPermissionStatus.unknown,
    this.businesses = const [],
    this.selectedCategory = 'Top',
    this.city = 'Bogota',
    this.countryCode = 'CO',
    this.experienceMode = ExperienceMode.night,
    this.errorMessage,
    this.usingLocation = false,
    this.location,
    this.categories = const [],
  });

  final HomeDiscoveryStatus status;
  final AppLocationPermissionStatus permissionStatus;
  final List<BusinessSummary> businesses;
  final String selectedCategory;
  final String city;
  final String countryCode;
  final ExperienceMode experienceMode;
  final String? errorMessage;
  final bool usingLocation;
  final AppLocation? location;
  final List<String> categories;

  HomeDiscoveryState copyWith({
    HomeDiscoveryStatus? status,
    AppLocationPermissionStatus? permissionStatus,
    List<BusinessSummary>? businesses,
    String? selectedCategory,
    String? city,
    String? countryCode,
    ExperienceMode? experienceMode,
    String? errorMessage,
    bool clearError = false,
    bool? usingLocation,
    AppLocation? location,
    List<String>? categories,
  }) {
    return HomeDiscoveryState(
      status: status ?? this.status,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      businesses: businesses ?? this.businesses,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      city: city ?? this.city,
      countryCode: countryCode ?? this.countryCode,
      experienceMode: experienceMode ?? this.experienceMode,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      usingLocation: usingLocation ?? this.usingLocation,
      location: location ?? this.location,
      categories: categories ?? this.categories,
    );
  }
}
