import '../../../../core/location/app_location.dart';
import '../../../../core/result/result.dart';
import '../../../../core/experience/experience_mode.dart';
import '../entities/business_summary.dart';

abstract interface class DiscoveryRepository {
  Future<Result<List<BusinessSummary>>> nearbyBusinesses({
    required AppLocation location,
    required ExperienceMode experienceMode,
    required String countryCode,
    required String city,
    String? category,
    String? search,
    String? kidId,
  });

  Future<Result<List<BusinessSummary>>> businessesByCategory(
    String category, {
    AppLocation? location,
    required ExperienceMode experienceMode,
    required String countryCode,
    required String city,
    String? kidId,
  });

  Future<Result<List<BusinessSummary>>> businessesByCity(
    String city, {
    AppLocation? location,
    required ExperienceMode experienceMode,
    required String countryCode,
    String? kidId,
  });

  Future<Result<List<BusinessSummary>>> searchBusinesses(
    String query, {
    AppLocation? location,
    required ExperienceMode experienceMode,
    required String countryCode,
    required String city,
    String? category,
    String? kidId,
  });
}
