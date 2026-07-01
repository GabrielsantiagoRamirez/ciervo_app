import 'package:dio/dio.dart';

import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../dtos/update_profile_request_dto.dart';
import '../dtos/user_profile_dto.dart';

class ProfilePhotoUpload {
  const ProfilePhotoUpload({
    required this.mediaId,
    this.photoUrl,
    this.imageUrl,
    this.storagePath,
    this.photoUpdatedAt,
  });

  final String mediaId;
  final String? photoUrl;
  final String? imageUrl;
  final String? storagePath;
  final DateTime? photoUpdatedAt;
}

abstract interface class ProfileRemoteDataSource {
  Future<UserProfileDto> getMe();

  Future<UserProfileDto> updateMe(UpdateProfileRequestDto request);

  Future<ProfilePhotoUpload> uploadPhoto({
    required String path,
    required String fileName,
  });

  Future<ProfilePhotoUpload> registerPhotoFromFirebase({
    required String imageUrl,
    required String storagePath,
    String? thumbnailUrl,
    String? mediaType,
  });
}

class DioProfileRemoteDataSource implements ProfileRemoteDataSource {
  const DioProfileRemoteDataSource(this._client);

  final NetworkClient _client;

  @override
  Future<UserProfileDto> getMe() async {
    UserProfileDto profile;
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/clients/me',
      );
      profile = UserProfileDto.fromJson(unwrapApiMap(response.data));
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) rethrow;
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/api/users/me',
      );
      return UserProfileDto.fromJson(unwrapApiMap(response.data));
    }

    if (_hasPhoto(profile)) return profile;

    try {
      final userResponse = await _client.dio.get<Map<String, dynamic>>(
        '/api/users/me',
      );
      final userProfile = UserProfileDto.fromJson(
        unwrapApiMap(userResponse.data),
      );
      if (_hasPhoto(userProfile)) {
        return UserProfileDto(
          id: profile.id,
          firstName: profile.firstName,
          lastName: profile.lastName,
          email: profile.email,
          phone: profile.phone,
          ciervoUserCode: profile.ciervoUserCode ?? userProfile.ciervoUserCode,
          identityDocument: profile.identityDocument,
          documentType: profile.documentType,
          photoUrl: userProfile.photoUrl,
          currentLatitude: profile.currentLatitude,
          currentLongitude: profile.currentLongitude,
          locationUpdatedAt: profile.locationUpdatedAt,
          city: profile.city,
          countryCode: profile.countryCode,
        );
      }
    } catch (_) {}

    return profile;
  }

  bool _hasPhoto(UserProfileDto profile) {
    final photo = profile.photoUrl?.trim();
    return photo != null && photo.isNotEmpty;
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
  Future<ProfilePhotoUpload> registerPhotoFromFirebase({
    required String imageUrl,
    required String storagePath,
    String? thumbnailUrl,
    String? mediaType,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/api/users/me/photo/register',
      data: {
        'imageUrl': imageUrl,
        'storagePath': storagePath,
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
          'thumbnailUrl': thumbnailUrl,
        if (mediaType != null && mediaType.isNotEmpty) 'mediaType': mediaType,
      },
    );
    final data = unwrapApiMap(response.data);
    final value = data['value'] is Map ? data['value'] as Map : data;
    final mediaId = value['mediaId'] ??
        value['MediaId'] ??
        value['id'] ??
        value['photoMediaId'] ??
        storagePath;
    return ProfilePhotoUpload(
      mediaId: mediaId.toString(),
      photoUrl: value['photoUrl']?.toString() ?? imageUrl,
      imageUrl: value['imageUrl']?.toString() ?? imageUrl,
      storagePath: value['storagePath']?.toString() ?? storagePath,
      photoUpdatedAt: DateTime.tryParse(
        '${value['photoUpdatedAt'] ?? value['updatedAt'] ?? ''}',
      ),
    );
  }

  @override
  Future<ProfilePhotoUpload> uploadPhoto({
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
    final mediaId = data['mediaId'] ??
        data['MediaId'] ??
        data['id'] ??
        data['photoMediaId'];
    if (mediaId == null || mediaId.toString().isEmpty) {
      throw const FormatException('El servidor no devolvió el ID de la foto.');
    }
    final photoUrl = data['photoUrl'] ?? data['PhotoUrl'] ?? data['publicUrl'];
    return ProfilePhotoUpload(
      mediaId: mediaId.toString(),
      photoUrl: photoUrl?.toString(),
    );
  }
}
