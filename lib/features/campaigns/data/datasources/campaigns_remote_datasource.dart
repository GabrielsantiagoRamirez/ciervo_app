import 'package:dio/dio.dart';

import '../../../../core/network/network_client.dart';
import '../../domain/entities/paid_campaign.dart';
import '../dtos/paid_campaign_dto.dart';

abstract interface class CampaignsRemoteDataSource {
  Future<List<PaidCampaignDto>> active(CampaignFilters filters);

  Future<void> registerView(String campaignId);

  Future<void> registerClick(String campaignId);
}

class DioCampaignsRemoteDataSource implements CampaignsRemoteDataSource {
  const DioCampaignsRemoteDataSource(this._client);

  final NetworkClient _client;

  static const _paths = [
    '/api/campaigns',
    '/api/ads/campaigns',
    '/api/discovery/campaigns',
  ];

  static const _viewPaths = [
    '/api/campaigns/{id}/view',
    '/api/ads/campaigns/{id}/view',
  ];

  static const _clickPaths = [
    '/api/campaigns/{id}/click',
    '/api/ads/campaigns/{id}/click',
  ];

  @override
  Future<List<PaidCampaignDto>> active(CampaignFilters filters) async {
    DioException? lastError;
    for (final path in _paths) {
      try {
        final response = await _client.dio.get<dynamic>(
          path,
          queryParameters: filters.toQueryParameters(),
        );
        return PaidCampaignDto.listFromResponse(response.data);
      } on DioException catch (error) {
        lastError = error;
        if (error.response?.statusCode != 404) rethrow;
      }
    }
    if (lastError != null) throw lastError;
    return const [];
  }

  @override
  Future<void> registerView(String campaignId) async {
    await _postFirstOk(_viewPaths, campaignId);
  }

  @override
  Future<void> registerClick(String campaignId) async {
    await _postFirstOk(_clickPaths, campaignId);
  }

  Future<void> _postFirstOk(List<String> templates, String campaignId) async {
    for (final template in templates) {
      try {
        await _client.dio.post<void>(
          template.replaceFirst('{id}', campaignId),
        );
        return;
      } on DioException catch (error) {
        if (error.response?.statusCode != 404) rethrow;
      }
    }
  }
}
