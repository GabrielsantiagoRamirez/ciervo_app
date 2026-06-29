import '../../../../core/errors/error_mapper.dart';
import '../../../../core/experience/experience_mode.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/business_summary.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../datasources/discovery_remote_datasource.dart';

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
      );
      return Success(businesses.map((item) => item.toDomain()).toList());
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
  }) async {
    try {
      final businesses = await _remoteDataSource.businessesByCategory(
        category,
        location: location,
        experienceMode: experienceMode,
        countryCode: countryCode,
        city: city,
        kidId: kidId,
      );
      return Success(businesses.map((item) => item.toDomain()).toList());
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
  }) async {
    try {
      final businesses = await _remoteDataSource.businessesByCity(
        city,
        location: location,
        experienceMode: experienceMode,
        countryCode: countryCode,
        kidId: kidId,
      );
      return Success(businesses.map((item) => item.toDomain()).toList());
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
      );
      return Success(businesses.map((item) => item.toDomain()).toList());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
