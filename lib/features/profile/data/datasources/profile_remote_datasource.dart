import 'package:dio/dio.dart';

import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../dtos/update_profile_request_dto.dart';
import '../dtos/user_profile_dto.dart';

abstract interface class ProfileRemoteDataSource {
  Future<UserProfileDto> getMe();

  Future<UserProfileDto> updateMe(UpdateProfileRequestDto request);
  Future<String> uploadPhoto({required String path, required String fileName});
}

class DioProfileRemoteDataSource implements ProfileRemoteDataSource {
  const DioProfileRemoteDataSource(this._client);

  final NetworkClient _client;

  @override
  Future<UserProfileDto> getMe() async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/clients/me',
      );
      return UserProfileDto.fromJson(unwrapApiMap(response.data));
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) rethrow;
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/users/me',
      );
      return UserProfileDto.fromJson(unwrapApiMap(response.data));
    }
  }

  @override
  Future<UserProfileDto> updateMe(UpdateProfileRequestDto request) async {
    try {
      final response = await _client.dio.put<Map<String, dynamic>>(
        '/api/clients/me',
        data: request.toJson(),
      );
      return UserProfileDto.fromJson(unwrapApiMap(response.data));
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) rethrow;
      final response = await _client.dio.put<Map<String, dynamic>>(
        '/api/users/me',
        data: request.toJson(),
      );
      return UserProfileDto.fromJson(unwrapApiMap(response.data));
    }
  }

  @override
  Future<String> uploadPhoto({
    required String path,
    required String fileName,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/users/me/photo',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: fileName),
      }),
    );
    final data = unwrapApiMap(response.data);
    final mediaId = data['mediaId'] ?? data['id'] ?? data['photoMediaId'];
    if (mediaId == null || mediaId.toString().isEmpty) {
      throw const FormatException('El servidor no devolvio el ID de la foto.');
    }
    return mediaId.toString();
  }
}
