import 'package:dio/dio.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/result/result.dart';
import '../domain/entities/place_detail.dart';

class BusinessDetailRepository {
  const BusinessDetailRepository(this._client);

  final NetworkClient _client;

  Future<Result<BusinessPublicDetail>> publicDetail(
    String businessId, {
    AppLocation? location,
  }) => _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/businesses/$businessId/public-detail',
          queryParameters: {
            if (location != null) ...{
              'latitude': location.latitude,
              'longitude': location.longitude,
            },
          },
        );
        return BusinessPublicDetail.fromJson(unwrapApiMap(response.data));
      });

  Future<Result<List<BusinessProduct>>> products(String businessId) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/businesses/$businessId/products',
        );
        return unwrapApiList(response.data)
            .whereType<Map<String, dynamic>>()
            .map(BusinessProduct.fromJson)
            .where((item) => item.isAvailable)
            .toList();
      });

  Future<Result<List<ReservableOption>>> reservableOptions(
    String businessId,
  ) => _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/businesses/$businessId/reservable-options',
        );
        return unwrapApiList(response.data)
            .whereType<Map<String, dynamic>>()
            .map(ReservableOption.fromJson)
            .where((item) => item.isActive)
            .toList();
      });

  Future<Result<DeliveryAvailability>> deliveryAvailability(
    String businessId, {
    AppLocation? location,
  }) => _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/businesses/$businessId/delivery-availability',
          queryParameters: {
            if (location != null) ...{
              'latitude': location.latitude,
              'longitude': location.longitude,
            },
          },
        );
        return DeliveryAvailability.fromJson(unwrapApiMap(response.data));
      });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on DioException catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}

class BusinessPublicDetail {
  const BusinessPublicDetail({
    required this.products,
    required this.reservableOptions,
    required this.name,
    required this.description,
    required this.categoryName,
    required this.address,
    required this.city,
    this.latitude,
    this.longitude,
    required this.distanceKm,
    required this.imageUrl,
    required this.gallery,
    required this.promotions,
    this.userCiervoCode,
    this.publicUrl,
    this.shareTitle,
    this.shareDescription,
    this.shareImageUrl,
    this.reviews = const [],
    this.ratingAverage,
    this.reviewsCount,
    this.score,
    this.likes,
    this.hasReviewed = false,
    this.userReviewId,
    this.canReview = false,
    this.reviewSourceType,
    this.reviewSourceId,
    this.reviewEligibilityReason,
    this.isFavorite = false,
  });

  factory BusinessPublicDetail.fromJson(Map<String, dynamic> json) =>
      BusinessPublicDetail(
        name: _string(json, const ['name', 'businessName', 'title']),
        description: _string(json, const ['description']),
        categoryName: _categoryName(json['category']) ??
            _string(json, const ['categoryName', 'category']),
        address: _string(json, const ['address']),
        city: _string(json, const ['city']),
        latitude: _doubleOrNull(json['latitude']),
        longitude: _doubleOrNull(json['longitude']),
        distanceKm: _doubleOrNull(json['distanceKm']) ?? 0,
        imageUrl: _mediaUrl(json['media']) ??
            _string(json, const ['coverUrl', 'mainImageUrl', 'imageUrl']),
        gallery: _gallery(json['media']),
        products: _list(json['products'])
            .map(BusinessProduct.fromJson)
            .where((item) => item.isAvailable)
            .toList(),
        reservableOptions: _list(json['reservableOptions'])
            .map(ReservableOption.fromJson)
            .where((item) => item.isActive)
            .toList(),
        promotions: _list(json['promotions']).map(_promotionFromJson).toList(),
        userCiervoCode: _stringOrNull(json, const [
          'userCiervoCode',
          'userPublicCode',
          'ciervoUserCode',
        ]),
        publicUrl: _stringOrNull(json, const ['publicUrl']),
        shareTitle: _stringOrNull(json, const ['shareTitle']),
        shareDescription: _stringOrNull(json, const ['shareDescription']),
        shareImageUrl: _stringOrNull(json, const ['shareImageUrl']),
        reviews: _list(json['reviews']).map(_reviewFromJson).toList(),
        ratingAverage: _doubleOrNull(json['ratingAverage'] ?? json['score']),
        reviewsCount: _intOrNull(json['reviewsCount']),
        score: _doubleOrNull(json['score']),
        likes: _intOrNull(json['likes']),
        hasReviewed: _bool(json['hasReviewed']),
        userReviewId: _intOrNull(json['userReviewId']),
        canReview: _bool(json['canReview']),
        reviewSourceType: _stringOrNull(json, const ['reviewSourceType']),
        reviewSourceId: _intOrNull(json['reviewSourceId']),
        reviewEligibilityReason:
            _stringOrNull(json, const ['reviewEligibilityReason']),
        isFavorite: _bool(json['isFavorite']),
      );

  final List<BusinessProduct> products;
  final List<ReservableOption> reservableOptions;
  final String name;
  final String description;
  final String categoryName;
  final String address;
  final String city;
  final double? latitude;
  final double? longitude;
  final double distanceKm;
  final String imageUrl;
  final List<String> gallery;
  final List<PlacePromotion> promotions;
  final String? userCiervoCode;
  final String? publicUrl;
  final String? shareTitle;
  final String? shareDescription;
  final String? shareImageUrl;
  final List<PlaceReview> reviews;
  final double? ratingAverage;
  final int? reviewsCount;
  final double? score;
  final int? likes;
  final bool hasReviewed;
  final int? userReviewId;
  final bool canReview;
  final String? reviewSourceType;
  final int? reviewSourceId;
  final String? reviewEligibilityReason;
  final bool isFavorite;
}

class BusinessProduct {
  const BusinessProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
    required this.allowsDelivery,
    required this.allowsPickup,
    this.preparationTimeMinutes,
  });

  factory BusinessProduct.fromJson(Map<String, dynamic> json) =>
      BusinessProduct(
        id: _string(json, const ['id', 'productId']),
        name: _string(json, const ['name', 'productName']),
        description: _string(json, const ['description']),
        price: _num(json['price']) ?? 0,
        imageUrl: _string(json, const [
          'imageUrl',
          'imageMediaId',
          'mediaId',
          'photoMediaId',
        ]),
        isAvailable: _bool(json['isAvailable'], fallback: true),
        allowsDelivery: _bool(json['allowsDelivery']),
        allowsPickup: _bool(json['allowsPickup']),
        preparationTimeMinutes: _intOrNull(json['preparationTimeMinutes']),
      );

  final String id;
  final String name;
  final String description;
  final num price;
  final String imageUrl;
  final bool isAvailable;
  final bool allowsDelivery;
  final bool allowsPickup;
  final int? preparationTimeMinutes;
}

class ReservableOption {
  const ReservableOption({
    required this.id,
    required this.name,
    required this.capacity,
    required this.isActive,
  });

  factory ReservableOption.fromJson(Map<String, dynamic> json) =>
      ReservableOption(
        id: _int(json['id'] ?? json['reservableOptionId']),
        name: _string(json, const ['name', 'title', 'type']),
        capacity: _int(json['capacity'] ?? json['maxPeople'] ?? json['people']),
        isActive: _bool(json['isActive'], fallback: true),
      );

  final int id;
  final String name;
  final int capacity;
  final bool isActive;
}

class DeliveryAvailability {
  const DeliveryAvailability({
    required this.deliveryAvailable,
    this.estimatedDeliveryFee,
    this.estimatedCourierEarning,
    this.platformFee,
    this.countryCode,
    this.currency,
    this.message,
  });

  factory DeliveryAvailability.fromJson(Map<String, dynamic> json) =>
      DeliveryAvailability(
        deliveryAvailable: _bool(
          json['deliveryAvailable'] ?? json['isAvailable'] ?? json['available'],
        ),
        estimatedDeliveryFee: _num(json['estimatedDeliveryFee']),
        estimatedCourierEarning: _num(json['estimatedCourierEarning']),
        platformFee: _num(json['platformFee']),
        countryCode: _stringOrNull(json, const ['countryCode']),
        currency: _stringOrNull(json, const ['currency', 'currencyCode']),
        message: _stringOrNull(json, const ['message', 'reason', 'msg']),
      );

  final bool deliveryAvailable;
  final num? estimatedDeliveryFee;
  final num? estimatedCourierEarning;
  final num? platformFee;
  final String? countryCode;
  final String? currency;
  final String? message;
}

String _string(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }
  return '';
}

String? _stringOrNull(Map<String, dynamic> json, List<String> keys) {
  final value = _string(json, keys);
  return value.isEmpty ? null : value;
}

int _int(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;

int? _intOrNull(dynamic value) =>
    value is int ? value : int.tryParse('${value ?? ''}');

num? _num(dynamic value) => value is num ? value : num.tryParse('$value');

double? _doubleOrNull(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('${value ?? ''}');

bool _bool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value == null) return fallback;
  return value.toString().toLowerCase() == 'true';
}

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().toList();
}

String? _categoryName(dynamic value) {
  if (value is Map) {
    return _string(Map<String, dynamic>.from(value), const ['name', 'code']);
  }
  return value?.toString();
}

String? _mediaUrl(dynamic value) {
  if (value is! Map) return null;
  final media = Map<String, dynamic>.from(value);
  return _stringOrNull(media, const [
    'mainImageUrl',
    'coverUrl',
    'logoUrl',
  ]);
}

List<String> _gallery(dynamic value) {
  if (value is! Map) return const [];
  final media = Map<String, dynamic>.from(value);
  final items = media['gallery'];
  if (items is! List) {
    return [
      ?_stringOrNull(media, const ['mainImageUrl', 'coverUrl', 'logoUrl']),
    ];
  }
  final urls = items
      .map((item) {
        if (item is String) return item;
        if (item is Map) {
          return _stringOrNull(Map<String, dynamic>.from(item), const [
            'url',
            'imageUrl',
            'mediaId',
            'id',
          ]);
        }
        return null;
      })
      .whereType<String>()
      .where((item) => item.isNotEmpty)
      .toList();
  final primary = _stringOrNull(media, const ['mainImageUrl', 'coverUrl']);
  if (primary != null && primary.isNotEmpty && !urls.contains(primary)) {
    urls.insert(0, primary);
  }
  return urls;
}

PlacePromotion _promotionFromJson(Map<String, dynamic> json) => PlacePromotion(
      title: _string(json, const ['title', 'name']),
      description: _string(json, const ['description']),
    );

PlaceReview _reviewFromJson(Map<String, dynamic> json) => PlaceReview(
      id: _intOrNull(json['id'] ?? json['reviewId']),
      userName: _string(json, const [
        'userDisplayName',
        'userName',
        'clientName',
        'name',
      ]),
      comment: _string(json, const ['comment', 'description']),
      rating: _doubleOrNull(json['rating']) ?? 0,
      timeAgo: _string(json, const ['createdAt', 'updatedAt']),
    );
