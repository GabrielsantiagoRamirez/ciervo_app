import 'package:dio/dio.dart';
import 'dart:typed_data';

import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';

class MediaAsset {
  const MediaAsset({required this.id});
  final String id;

  factory MediaAsset.fromJson(Map<String, dynamic> json) => MediaAsset(
    id: '${json['id'] ?? json['mediaId'] ?? ''}',
  );
}

class MediaRepository {
  const MediaRepository(this._client);
  final NetworkClient _client;

  Future<Result<MediaAsset>> upload({
    required String path,
    required String fileName,
  }) => _guard(() async {
    final response = await _client.dio.post<dynamic>(
      '/api/media/upload',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: fileName),
      }),
    );
    return MediaAsset.fromJson(unwrapApiMap(response.data));
  });

  Future<Result<MediaAsset>> get(String id) => _guard(() async {
    final response = await _client.dio.get<dynamic>('/api/media/$id');
    return MediaAsset.fromJson(unwrapApiMap(response.data));
  });

  Future<Result<Uint8List>> download(String id, {bool thumbnail = false}) =>
      _guard(() async {
        final response = await _client.dio.get<List<int>>(
          '/api/media/$id/${thumbnail ? 'thumbnail' : 'download'}',
          options: Options(responseType: ResponseType.bytes),
        );
        return Uint8List.fromList(response.data ?? const []);
      });

  Future<Result<void>> delete(String id) => _guard(() async {
    await _client.dio.delete<void>('/api/media/$id');
  });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
