import '../../../../core/errors/error_mapper.dart';
import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/activity_feed_item.dart';

class ActivityFeedRepository {
  const ActivityFeedRepository(this._client);

  final NetworkClient _client;

  Future<Result<List<ActivityFeedItem>>> feed() => _guard(() async {
    final response =
        await _client.dio.get<dynamic>('/api/discovery/activity-feed');
    return unwrapApiList(response.data)
        .whereType<Map<String, dynamic>>()
        .map(_fromJson)
        .toList();
  });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}

ActivityFeedItem _fromJson(Map<String, dynamic> json) => ActivityFeedItem(
  id: '${json['id'] ?? json['activityId'] ?? ''}',
  type: '${json['type'] ?? json['activityType'] ?? ''}',
  title: _s(json, const ['title', 'name']).isEmpty
      ? 'Novedad Ciervo'
      : _s(json, const ['title', 'name']),
  description: _s(json, const ['description', 'message', 'body']),
  category: _nullable(json['category']),
  businessId: _i(json['businessId']),
  eventId: _i(json['eventId']),
  productId: _i(json['productId']),
  promotionId: _i(json['promotionId']),
  giftCardId: _i(json['giftCardId']),
  benefitId: _i(json['benefitId']),
  rewardId: _i(json['rewardId']),
  couponId: _i(json['couponId']),
  bonusId: _nullable(json['bonusId'] ?? json['linkedBonusId']),
  campaignId: _nullable(json['campaignId'] ?? json['adsCampaignId']),
  deepLink: _nullable(json['deepLink']),
  imageMediaId: _nullable(
    json['imageMediaId'] ?? json['mediaId'] ?? json['coverMediaId'],
  ),
  createdAt: DateTime.tryParse('${json['createdAt'] ?? json['date'] ?? ''}'),
);

String _s(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }
  return '';
}

String? _nullable(dynamic value) =>
    value == null || value.toString().isEmpty ? null : value.toString();

int? _i(dynamic value) => value is int ? value : int.tryParse('$value');
