import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/auth_token_claims.dart';
import '../../../../core/session/session_manager.dart';
import 'move_image_processor.dart';
import 'move_media_models.dart';

class MoveMediaRepository {
  const MoveMediaRepository({
    required NetworkClient client,
    required SessionManager sessionManager,
    MoveImageProcessor imageProcessor = const MoveImageProcessor(),
  }) : _client = client,
       _sessionManager = sessionManager,
       _imageProcessor = imageProcessor;

  final NetworkClient _client;
  final SessionManager _sessionManager;
  final MoveImageProcessor _imageProcessor;

  Future<Result<MoveMediaAsset>> uploadImage({
    required String path,
    required String originalFileName,
    MoveUploadProgress? onProgress,
    CancelToken? cancelToken,
  }) => _guard(() async {
    final prepared = await _imageProcessor.processFile(
      path,
      originalFileName: originalFileName,
    );
    return _uploadPrepared(
      prepared,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  });

  Future<MoveMediaAsset> _uploadPrepared(
    PreparedMoveImage image, {
    MoveUploadProgress? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (image.mimeType != 'image/jpeg' ||
        image.bytes.isEmpty ||
        image.bytes.length > 5 * 1024 * 1024) {
      throw const AppException(
        message: 'La imagen MOVE no fue procesada de forma segura.',
        code: 'move_media_not_prepared',
      );
    }
    final ownerId = await _ownerIdFromJwt();
    final response = await _client.dio.post<dynamic>(
      '/api/media/upload',
      data: FormData.fromMap({
        'ownerType': 'User',
        'ownerId': ownerId,
        'mediaType': 'Gallery',
        'file': MultipartFile.fromBytes(
          image.bytes,
          filename: image.fileName,
          contentType: MediaType.parse(image.mimeType),
        ),
      }),
      cancelToken: cancelToken,
      onSendProgress: onProgress,
    );
    return MoveMediaAsset.fromJson(unwrapApiMap(response.data));
  }

  Future<Result<MoveMediaAsset>> metadata(MoveMediaAsset asset) => _guard(
    () async {
      final response = await _client.dio.get<dynamic>('/api/media/${asset.id}');
      return MoveMediaAsset.fromJson(unwrapApiMap(response.data));
    },
  );

  Future<Result<MoveMediaDownload>> download(MoveMediaAsset asset) =>
      _guard(() async {
        final response = await _client.dio.get<List<int>>(
          '/api/media/${asset.id}/download',
          options: Options(responseType: ResponseType.bytes),
        );
        return MoveMediaDownload(
          bytes: Uint8List.fromList(response.data ?? const <int>[]),
          contentType: response.headers.value(Headers.contentTypeHeader),
          fileName: _downloadFileName(
            response.headers.value('content-disposition'),
          ),
        );
      });

  /// Borra exclusivamente un asset de borrador que el caller confirmó que aún
  /// no está referenciado por identidad, licencia, vehículo o submit.
  Future<Result<void>> deleteDraft(MoveMediaAsset orphan) => _guard(() async {
    await _client.dio.delete<void>('/api/media/${orphan.id}');
  });

  /// Limpieza explícita y best-effort al reemplazar/cancelar un borrador.
  ///
  /// [referenced] debe contener todos los assets que el borrador conserva. Los
  /// fallos se devuelven para permitir reintentar sin perder su identidad.
  Future<MoveOrphanCleanupResult> cleanupOrphans({
    required Iterable<MoveMediaAsset> uploaded,
    required Iterable<MoveMediaAsset> referenced,
  }) async {
    final referencedIds = referenced.map((asset) => asset.id).toSet();
    final deleted = <MoveMediaAsset>[];
    final failed = <MoveMediaAsset>[];
    for (final asset in uploaded) {
      if (referencedIds.contains(asset.id)) continue;
      final result = await deleteDraft(asset);
      switch (result) {
        case Success<void>():
          deleted.add(asset);
        case Failure<void>():
          failed.add(asset);
      }
    }
    return MoveOrphanCleanupResult(deleted: deleted, failed: failed);
  }

  Future<String> _ownerIdFromJwt() async {
    final token = await _sessionManager.accessToken();
    if (token == null || token.isEmpty) {
      throw const AppException(
        message: 'Inicia sesion como cliente para subir documentos.',
        code: 'move_media_unauthenticated',
      );
    }
    final claims = AuthTokenClaims.fromJwt(token);
    final ownerId = claims.userId?.trim();
    if (!claims.isExplicitClient || ownerId == null || ownerId.isEmpty) {
      throw const AppException(
        message: 'La sesion no pertenece a un cliente valido.',
        code: 'move_media_invalid_owner',
      );
    }
    return ownerId;
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  static String? _downloadFileName(String? disposition) {
    if (disposition == null) return null;
    final match = RegExp(
      r'''filename\*?=(?:UTF-8''|")?([^";]+)''',
      caseSensitive: false,
    ).firstMatch(disposition);
    return match?.group(1);
  }
}
