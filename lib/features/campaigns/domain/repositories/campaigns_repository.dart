import '../../../../core/result/result.dart';
import '../entities/paid_campaign.dart';

abstract interface class CampaignsRepository {
  Future<Result<List<PaidCampaign>>> active(CampaignFilters filters);

  Future<Result<void>> registerView(String campaignId);

  Future<Result<void>> registerClick(String campaignId);
}
