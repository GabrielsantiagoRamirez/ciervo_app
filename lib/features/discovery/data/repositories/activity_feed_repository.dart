import '../../../../core/errors/error_mapper.dart';
import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/activity_feed_item.dart';

class ActivityFeedRepository {
  const ActivityFeedRepository(this._client);

  final NetworkClient _client;

  Future<Result<List<ActivityFeedItem>>> feed() => _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/discovery/activity-feed',
        );
        return unwrapApiList(response.data)
            .whereType<Map>()
            .map((item) => _fromJson(Map<String, dynamic>.from(item)))
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

ActivityFeedItem _fromJson(Map<String, dynamic> json) {
  final cashbackAmount = _d(
    json['cashbackAmount'] ??
        json['cashbackValue'] ??
        json['cashback'] ??
        json['cashbackReward'],
  );
  final cashbackPercent = _d(
    json['cashbackPercent'] ??
        json['cashbackPercentage'] ??
        json['cashbackRate'],
  );
  final points = _i(
    json['points'] ??
        json['rewardPoints'] ??
        json['pointsReward'] ??
        json['loyaltyPoints'],
  );
  final hasCashback = _bool(
        json['hasCashback'] ?? json['cashbackEnabled'] ?? json['offersCashback'],
      ) ||
      (cashbackAmount != null && cashbackAmount > 0) ||
      (cashbackPercent != null && cashbackPercent > 0);
  final hasPoints = _bool(
        json['hasPoints'] ?? json['pointsEnabled'] ?? json['offersPoints'],
      ) ||
      (points != null && points > 0);

  return ActivityFeedItem(
    id: '${json['id'] ?? json['activityId'] ?? ''}',
    type: '${json['type'] ?? json['activityType'] ?? ''}',
    title: _s(json, const ['title', 'name', 'productName', 'promotionTitle'])
            .isEmpty
        ? 'Novedad Ciervo'
        : _s(json, const ['title', 'name', 'productName', 'promotionTitle']),
    description: _s(json, const ['description', 'message', 'body']),
    category: _nullable(json['category'] ?? json['categoryName']),
    businessId: _i(json['businessId'] ?? json['storeId'] ?? json['clubId']),
    businessName: _nullable(
      json['businessName'] ?? json['storeName'] ?? json['clubName'],
    ),
    eventId: _i(json['eventId']),
    productId: _i(json['productId']),
    promotionId: _i(json['promotionId'] ?? json['marketplacePromotionId']),
    giftCardId: _i(json['giftCardId']),
    benefitId: _i(json['benefitId']),
    rewardId: _i(json['rewardId']),
    couponId: _i(json['couponId']),
    bonusId: _nullable(json['bonusId'] ?? json['linkedBonusId']),
    campaignId: _nullable(json['campaignId'] ?? json['adsCampaignId']),
    deepLink: _nullable(json['deepLink']),
    imageMediaId: _mediaIdOnly(
      json['imageMediaId'] ?? json['mediaId'] ?? json['coverMediaId'],
    ),
    imageUrl: _imageUrl(json),
    createdAt: DateTime.tryParse('${json['createdAt'] ?? json['date'] ?? ''}'),
    price: _d(json['price'] ?? json['offerPrice'] ?? json['amount']),
    currency: _s(json, const ['currency']).isEmpty
        ? 'COP'
        : _s(json, const ['currency']),
    cashbackAmount: cashbackAmount,
    cashbackPercent: cashbackPercent,
    cashbackLabel: _nullable(
      json['cashbackLabel'] ?? json['cashbackText'] ?? json['cashbackDisplay'],
    ),
    points: points,
    hasCashback: hasCashback,
    hasPoints: hasPoints,
    isFavoriteBusiness: _bool(
      json['isFavoriteBusiness'] ??
          json['isFavorite'] ??
          json['favoriteBusiness'],
    ),
  );
}

String? _imageUrl(Map<String, dynamic> json) {
  for (final key in const [
    'coverImageUrl',
    'productImageUrl',
    'imageUrl',
    'thumbnailUrl',
  ]) {
    final value = json[key]?.toString().trim();
    if (value != null &&
        value.isNotEmpty &&
        (value.startsWith('http://') || value.startsWith('https://'))) {
      return value;
    }
  }
  return null;
}

String? _mediaIdOnly(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  // Evitar meter URLs en /api/media/{id}/download.
  if (text.startsWith('http://') || text.startsWith('https://')) return null;
  return text;
}

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

double? _d(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

bool _bool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase();
  return text == 'true' || text == '1';
}
