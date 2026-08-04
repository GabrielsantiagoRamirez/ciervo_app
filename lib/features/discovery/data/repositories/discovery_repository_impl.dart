import '../../../../core/errors/error_mapper.dart';
import '../../../../core/experience/experience_mode.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/business_summary.dart';
import '../../domain/entities/discovery_smart_filters.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../datasources/discovery_remote_datasource.dart';
import '../dtos/business_summary_dto.dart';

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  const DiscoveryRepositoryImpl(this._remoteDataSource);

  final DiscoveryRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<BusinessSummary>>> nearbyBusinesses({
    required AppLocation location,
    required ExperienceMode experienceMode,
    required String countryCode,
    required String city,
    String? category,
    String? search,
    String? kidId,
    DiscoverySmartFilters filters = const DiscoverySmartFilters(),
  }) async {
    try {
      final businesses = await _remoteDataSource.nearbyBusinesses(
        location: location,
        experienceMode: experienceMode,
        countryCode: countryCode,
        city: city,
        category: category,
        search: search,
        kidId: kidId,
        filters: filters,
      );
      return Success(_toDomainFiltered(businesses, filters));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<BusinessSummary>>> businessesByCategory(
    String category, {
    AppLocation? location,
    required ExperienceMode experienceMode,
    required String countryCode,
    required String city,
    String? kidId,
    DiscoverySmartFilters filters = const DiscoverySmartFilters(),
  }) async {
    try {
      final businesses = await _remoteDataSource.businessesByCategory(
        category,
        location: location,
        experienceMode: experienceMode,
        countryCode: countryCode,
        city: city,
        kidId: kidId,
        filters: filters,
      );
      return Success(_toDomainFiltered(businesses, filters));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<BusinessSummary>>> businessesByCity(
    String city, {
    AppLocation? location,
    required ExperienceMode experienceMode,
    required String countryCode,
    String? kidId,
    DiscoverySmartFilters filters = const DiscoverySmartFilters(),
  }) async {
    try {
      final businesses = await _remoteDataSource.businessesByCity(
        city,
        location: location,
        experienceMode: experienceMode,
        countryCode: countryCode,
        kidId: kidId,
        filters: filters,
      );
      return Success(_toDomainFiltered(businesses, filters));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<BusinessSummary>>> searchBusinesses(
    String query, {
    AppLocation? location,
    required ExperienceMode experienceMode,
    required String countryCode,
    required String city,
    String? category,
    String? kidId,
    DiscoverySmartFilters filters = const DiscoverySmartFilters(),
  }) async {
    try {
      final businesses = await _remoteDataSource.searchBusinesses(
        query,
        location: location,
        experienceMode: experienceMode,
        countryCode: countryCode,
        city: city,
        category: category,
        kidId: kidId,
        filters: filters,
      );
      return Success(_toDomainFiltered(businesses, filters));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  List<BusinessSummary> _toDomainFiltered(
    List<BusinessSummaryDto> businesses,
    DiscoverySmartFilters filters,
  ) {
    final mapped = businesses.map((item) => item.toDomain());
    if (!filters.hasActiveFilters) {
      return mapped.toList();
    }
    return mapped.where(filters.matches).toList();
  }
}
