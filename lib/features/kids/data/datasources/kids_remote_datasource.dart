import 'package:dio/dio.dart';

import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../dtos/child_profile_dto.dart';
import '../dtos/kids_requests.dart';

abstract interface class KidsRemoteDataSource {
  Future<List<ChildProfileDto>> children();
  Future<ChildProfileDto> child(String childId);
  Future<ChildProfileDto> createChild(Map<String, dynamic> data);
  Future<ChildProfileDto> updateChild(
    String childId,
    Map<String, dynamic> data,
  );
  Future<void> deleteChild(String childId);
  Future<List<dynamic>> allowedBusinesses(String childId);
  Future<void> saveAllowedBusinesses(String childId, List<String> businessIds);
  Future<List<dynamic>> allowedCategories(String childId);
  Future<List<dynamic>> categoryCandidates(String childId);
  Future<List<dynamic>> businessCandidates(
    String childId, {
    String? query,
    String? city,
    int? categoryId,
    int page,
    int pageSize,
  });
  Future<Map<String, dynamic>> createChildWalletCard({
    required String childId,
    required String displayName,
    required String currency,
  });
  Future<void> saveAllowedCategories(String childId, List<int> categoryIds);
  Future<Map<String, dynamic>> spendingLimits(String childId);
  Future<Map<String, dynamic>> updateSpendingLimits(
    String childId,
    Map<String, dynamic> data,
  );
  Future<Map<String, dynamic>> childWallet(String childId);
  Future<List<dynamic>> childWalletCards(String childId);
  Future<List<dynamic>> childWalletHistory(String childId);
  Future<Map<String, dynamic>> rechargeChildWallet({
    required String childId,
    required String cardId,
    required double amount,
    required String currency,
  });

  Future<Map<String, dynamic>> payKidsBusiness({
    required String childProfileId,
    required String businessId,
    required double amount,
    required String currency,
    String? walletCardId,
    String? idempotencyKey,
  });
  Future<List<dynamic>> payForMeRequests();
  Future<void> approvePayForMeRequest(int requestId);
  Future<void> rejectPayForMeRequest(int requestId, {String? reason});
  Future<ChildProfileDto> linkChild(LinkChildRequest request);
  Future<ChildPhotoUpload> uploadChildPhoto({
    required String childId,
    required String path,
    required String fileName,
  });

  Future<Map<String, dynamic>> createKidAccount({
    required String childId,
    required String username,
    required String pin,
  });

  Future<void> updateKidPin({
    required String childId,
    required String pin,
  });
}

class DioKidsRemoteDataSource implements KidsRemoteDataSource {
  const DioKidsRemoteDataSource(this._client);

  final NetworkClient _client;

  @override
  Future<List<ChildProfileDto>> children() async {
    final response = await _client.dio.get<dynamic>('/api/guardians/children');
    return ChildProfileDto.listFrom(unwrapApiResponse(response.data));
  }

  @override
  Future<ChildProfileDto> child(String childId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/guardians/children/$childId',
    );
    return ChildProfileDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<ChildProfileDto> createChild(Map<String, dynamic> data) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/guardians/children',
      data: data,
    );
    return ChildProfileDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<ChildProfileDto> updateChild(
    String childId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/api/guardians/children/$childId',
      data: data,
    );
    return ChildProfileDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<void> deleteChild(String childId) async {
    await _client.dio.delete<void>('/api/guardians/children/$childId');
  }

  @override
  Future<List<dynamic>> categoryCandidates(String childId) async {
    try {
      return await _list('/api/kids/$childId/category-candidates');
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return allowedCategories(childId);
      }
      rethrow;
    }
  }

  @override
  Future<List<dynamic>> businessCandidates(
    String childId, {
    String? query,
    String? city,
    int? categoryId,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      return await _list(
        '/api/kids/$childId/business-candidates',
        queryParameters: {
          if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
          if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
          if (categoryId != null) 'categoryId': categoryId,
          'page': page,
          'pageSize': pageSize,
        },
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const [];
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> createChildWalletCard({
    required String childId,
    required String displayName,
    required String currency,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/guardians/children/$childId/wallet/cards',
      data: {'displayName': displayName, 'currency': currency},
    );
    return unwrapApiMap(response.data);
  }

  @override
  Future<List<dynamic>> allowedBusinesses(String childId) =>
      _list('/api/kids/$childId/allowed-businesses');

  @override
  Future<void> saveAllowedBusinesses(
    String childId,
    List<String> businessIds,
  ) async {
    await _client.dio.put<void>(
      '/api/kids/$childId/allowed-businesses',
      data: {'businessIds': businessIds.map(int.parse).toList()},
    );
  }

  @override
  Future<List<dynamic>> allowedCategories(String childId) =>
      _list('/api/kids/$childId/allowed-categories');

  @override
  Future<void> saveAllowedCategories(
    String childId,
    List<int> categoryIds,
  ) async {
    await _client.dio.put<void>(
      '/api/kids/$childId/allowed-categories',
      data: {'categoryIds': categoryIds},
    );
  }

  @override
  Future<Map<String, dynamic>> spendingLimits(String childId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/guardians/children/$childId/spending-limits',
    );
    return unwrapApiMap(response.data);
  }

  @override
  Future<Map<String, dynamic>> updateSpendingLimits(
    String childId,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/api/guardians/children/$childId/spending-limits',
      data: data,
    );
    return unwrapApiMap(response.data);
  }

  @override
  Future<Map<String, dynamic>> childWallet(String childId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/api/guardians/children/$childId/wallet',
    );
    return unwrapApiMap(response.data);
  }

  @override
  Future<List<dynamic>> childWalletCards(String childId) async {
    final response = await _client.dio.get<dynamic>(
      '/api/guardians/children/$childId/wallet/cards',
    );
    return unwrapApiList(response.data);
  }

  @override
  Future<List<dynamic>> childWalletHistory(String childId) async {
    final response = await _client.dio.get<dynamic>(
      '/api/guardians/children/$childId/wallet/history',
      queryParameters: const {'page': 1, 'pageSize': 50},
    );
    return unwrapApiList(response.data);
  }

  @override
  Future<Map<String, dynamic>> rechargeChildWallet({
    required String childId,
    required String cardId,
    required double amount,
    required String currency,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/guardians/children/$childId/wallet/cards/$cardId/recharge',
      data: {
        'amount': amount,
        'currency': currency,
        'idempotencyKey': 'kid-recharge-$childId-${DateTime.now().microsecondsSinceEpoch}',
      },
    );
    return unwrapApiMap(response.data);
  }

  @override
  Future<Map<String, dynamic>> payKidsBusiness({
    required String childProfileId,
    required String businessId,
    required double amount,
    required String currency,
    String? walletCardId,
    String? idempotencyKey,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/kids/payments/business',
      data: {
        'childId': int.tryParse(childProfileId) ?? childProfileId,
        'businessId': int.tryParse(businessId) ?? businessId,
        'amount': amount,
        'currency': currency,
        'idempotencyKey': idempotencyKey ??
            'kids-pay-$childProfileId-${DateTime.now().microsecondsSinceEpoch}',
        if (walletCardId != null)
          'childWalletCardId': int.tryParse(walletCardId) ?? walletCardId,
      },
    );
    return unwrapApiMap(response.data);
  }

  @override
  Future<List<dynamic>> payForMeRequests() async {
    return _list('/api/guardians/pay-for-me/requests');
  }

  @override
  Future<void> approvePayForMeRequest(int requestId) async {
    await _client.dio.post<void>(
      '/api/guardians/pay-for-me/requests/$requestId/approve',
    );
  }

  @override
  Future<void> rejectPayForMeRequest(int requestId, {String? reason}) async {
    await _client.dio.post<void>(
      '/api/guardians/pay-for-me/requests/$requestId/reject',
      data: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
  }

  @override
  Future<ChildProfileDto> linkChild(LinkChildRequest request) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/guardians/children/link',
      data: request.toJson(),
    );
    return ChildProfileDto.fromJson(unwrapApiMap(response.data));
  }

  @override
  Future<ChildPhotoUpload> uploadChildPhoto({
    required String childId,
    required String path,
    required String fileName,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/guardians/children/$childId/photo',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: fileName),
      }),
    );
    final data = unwrapApiMap(response.data);
    final mediaId = data['mediaId'] ?? data['MediaId'] ?? data['id'];
    final photoUrl = data['photoUrl'] ?? data['PhotoUrl'] ?? data['publicUrl'];
    return ChildPhotoUpload(
      mediaId: mediaId?.toString() ?? '',
      photoUrl: photoUrl?.toString(),
    );
  }

  Future<List<dynamic>> _list(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _client.dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
    );
    final value = unwrapApiResponse(response.data);
    if (value is List) return value;
    if (value is Map<String, dynamic> && value['items'] is List) {
      return value['items'] as List;
    }
    return const [];
  }

  @override
  Future<Map<String, dynamic>> createKidAccount({
    required String childId,
    required String username,
    required String pin,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/guardians/children/$childId/account',
      data: {
        'username': username.trim(),
        'pin': pin,
        'loginMethod': 'PIN',
      },
    );
    return unwrapApiMap(response.data);
  }

  @override
  Future<void> updateKidPin({
    required String childId,
    required String pin,
  }) async {
    await _client.dio.put<void>(
      '/api/guardians/children/$childId/account/pin',
      data: {'pin': pin},
    );
  }
}
