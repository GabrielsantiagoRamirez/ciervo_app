import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/paid_campaign.dart';
import '../../domain/repositories/campaigns_repository.dart';
import '../datasources/campaigns_remote_datasource.dart';

class CampaignsRepositoryImpl implements CampaignsRepository {
  const CampaignsRepositoryImpl(this._remote);

  final CampaignsRemoteDataSource _remote;

  @override
  Future<Result<List<PaidCampaign>>> active(CampaignFilters filters) =>
      _guard(() async {
        final dtos = await _remote.active(filters);
        return dtos.map((dto) => dto.toEntity()).toList();
      });

  @override
  Future<Result<void>> registerView(String campaignId) =>
      _guard(() => _remote.registerView(campaignId));

  @override
  Future<Result<void>> registerClick(String campaignId) =>
      _guard(() => _remote.registerClick(campaignId));

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
