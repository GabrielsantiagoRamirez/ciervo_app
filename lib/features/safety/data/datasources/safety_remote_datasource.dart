import 'package:dio/dio.dart';

import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../models/safety_models.dart';

abstract interface class SafetyRemoteDataSource {
  Future<UserReportModel> createReport({
    required ReportTargetType targetType,
    String? targetId,
    int? reportedUserId,
    required ReportReason reason,
    String? description,
  });

  Future<List<UserReportModel>> myReports();

  Future<void> blockUser(int userId);

  Future<void> unblockUser(int userId);

  Future<List<BlockedUserModel>> blockedUsers();

  Future<ContentBlockModel> blockContent({
    required ReportTargetType targetType,
    required String targetId,
  });

  Future<void> unblockContent({
    required ReportTargetType targetType,
    required String targetId,
  });

  Future<List<ContentBlockModel>> myContentBlocks();
}

class DioSafetyRemoteDataSource implements SafetyRemoteDataSource {
  const DioSafetyRemoteDataSource(this._client);

  final NetworkClient _client;

  @override
  Future<UserReportModel> createReport({
    required ReportTargetType targetType,
    String? targetId,
    int? reportedUserId,
    required ReportReason reason,
    String? description,
  }) async {
    final response = await _client.dio.post<dynamic>(
      '/api/reports',
      data: {
        'targetType': targetType.apiValue,
        if (targetId != null) 'targetId': targetId,
        if (reportedUserId != null) 'reportedUserId': reportedUserId,
        'reason': reason.apiValue,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return UserReportModel.fromJson(
      unwrapApiResponse(response.data) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<UserReportModel>> myReports() async {
    final response = await _client.dio.get<dynamic>('/api/reports/me');
    final value = unwrapApiResponse(response.data);
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(UserReportModel.fromJson)
        .toList();
  }

  @override
  Future<void> blockUser(int userId) async {
    await _client.dio.post<void>('/api/users/$userId/block');
  }

  @override
  Future<void> unblockUser(int userId) async {
    await _client.dio.delete<void>('/api/users/$userId/block');
  }

  @override
  Future<List<BlockedUserModel>> blockedUsers() async {
    try {
      final response = await _client.dio.get<dynamic>(
        '/api/users/me/blocked-users',
      );
      final value = unwrapApiResponse(response.data);
      if (value is! List) return const [];
      return value
          .whereType<Map<String, dynamic>>()
          .map(BlockedUserModel.fromJson)
          .toList();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return const [];
      rethrow;
    }
  }

  @override
  Future<ContentBlockModel> blockContent({
    required ReportTargetType targetType,
    required String targetId,
  }) async {
    final response = await _client.dio.post<dynamic>(
      '/api/content-blocks',
      data: {'targetType': targetType.apiValue, 'targetId': targetId},
    );
    return ContentBlockModel.fromJson(
      unwrapApiResponse(response.data) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> unblockContent({
    required ReportTargetType targetType,
    required String targetId,
  }) async {
    await _client.dio.delete<void>(
      '/api/content-blocks/${targetType.apiValue}/$targetId',
    );
  }

  @override
  Future<List<ContentBlockModel>> myContentBlocks() async {
    try {
      final response = await _client.dio.get<dynamic>('/api/content-blocks/me');
      final value = unwrapApiResponse(response.data);
      if (value is! List) return const [];
      return value
          .whereType<Map<String, dynamic>>()
          .map(ContentBlockModel.fromJson)
          .toList();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return const [];
      rethrow;
    }
  }
}
