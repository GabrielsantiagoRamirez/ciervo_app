import 'package:dio/dio.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../domain/entities/place_detail.dart';

class ReviewRepository {
  const ReviewRepository(this._client);

  final NetworkClient _client;

  Future<Result<List<PlaceReview>>> byBusiness(int businessId) => _guard(
        () async => unwrapApiList(
          (await _client.dio.get<dynamic>(
            '/api/reviews/by-business/$businessId',
          ))
              .data,
        ).whereType<Map<String, dynamic>>().map(_review).toList(),
      );

  Future<Result<void>> create({
    required int businessId,
    required int rating,
    String? sourceType,
    int? sourceId,
    String? comment,
    int? bookingId,
  }) =>
      _guard(() async {
        await _client.dio.post<dynamic>(
          '/api/reviews',
          data: {
            'businessId': businessId,
            'bookingId': ?bookingId,
            'sourceType': ?_nonEmpty(sourceType),
            'sourceId': ?sourceId,
            'rating': rating.clamp(1, 5),
            'comment': ?_nonEmpty(comment),
          },
        );
      });

  Future<Result<void>> update({
    required int reviewId,
    required int businessId,
    required int rating,
    String? sourceType,
    int? sourceId,
    String? comment,
    int? bookingId,
  }) =>
      _guard(() async {
        await _client.dio.put<dynamic>(
          '/api/reviews/$reviewId',
          data: {
            'businessId': businessId,
            'bookingId': ?bookingId,
            'sourceType': ?_nonEmpty(sourceType),
            'sourceId': ?sourceId,
            'rating': rating.clamp(1, 5),
            'comment': ?_nonEmpty(comment),
          },
        );
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

PlaceReview _review(Map<String, dynamic> json) => PlaceReview(
      id: int.tryParse('${json['id'] ?? json['reviewId'] ?? ''}'),
      userName: _value(json, const [
        'userDisplayName',
        'userName',
        'clientName',
        'name',
      ]),
      comment: _value(json, const ['comment', 'description']),
      rating: double.tryParse('${json['rating'] ?? 0}') ?? 0,
      timeAgo: _value(json, const ['createdAt', 'updatedAt']),
    );

String _value(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }
  return '';
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
