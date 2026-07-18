import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../../core/errors/app_exception.dart';
import 'move_media_models.dart';

class MoveImageProcessor {
  const MoveImageProcessor({
    this.maxInputBytes = 5 * 1024 * 1024,
    this.maxOutputBytes = 5 * 1024 * 1024,
    this.maxDimension = 2048,
  });

  final int maxInputBytes;
  final int maxOutputBytes;
  final int maxDimension;

  static const allowedExtensions = <String>{'jpg', 'jpeg', 'png', 'webp'};
  static const allowedMimeTypes = <String>{
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  };

  Future<PreparedMoveImage> processFile(
    String path, {
    required String originalFileName,
  }) async {
    final file = File(path);
    final length = await file.length();
    if (length <= 0 || length > maxInputBytes) {
      throw _invalidSize();
    }
    return processBytes(
      await file.readAsBytes(),
      originalFileName: originalFileName,
    );
  }

  Future<PreparedMoveImage> processBytes(
    Uint8List bytes, {
    required String originalFileName,
  }) async {
    _validateInput(bytes, originalFileName);
    final request = _ImageProcessingRequest(
      bytes,
      sanitizeFileName(originalFileName),
      maxOutputBytes,
      maxDimension,
    );
    return Isolate.run(() => _processImage(request));
  }

  void _validateInput(Uint8List bytes, String fileName) {
    if (bytes.isEmpty || bytes.length > maxInputBytes) {
      throw _invalidSize();
    }
    final extension = _extension(fileName);
    if (!allowedExtensions.contains(extension)) {
      throw const AppException(
        message: 'Selecciona una imagen JPG, PNG o WEBP.',
        code: 'move_media_extension_not_allowed',
      );
    }
    final mimeType = detectMimeType(bytes);
    if (mimeType == null || !allowedMimeTypes.contains(mimeType)) {
      throw const AppException(
        message: 'El contenido del archivo no es una imagen permitida.',
        code: 'move_media_signature_not_allowed',
      );
    }
  }

  static String sanitizeFileName(String value) {
    final leaf = value.replaceAll('\\', '/').split('/').last;
    final dot = leaf.lastIndexOf('.');
    final rawStem = dot > 0 ? leaf.substring(0, dot) : leaf;
    var stem = rawStem
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^[_-]+|[_-]+$'), '');
    if (stem.isEmpty) stem = 'move_image';
    if (stem.length > 64) stem = stem.substring(0, 64);
    return '$stem.jpg';
  }

  static String? detectMimeType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    return null;
  }

  static String _extension(String value) {
    final leaf = value.replaceAll('\\', '/').split('/').last;
    final dot = leaf.lastIndexOf('.');
    return dot < 0 ? '' : leaf.substring(dot + 1).toLowerCase();
  }

  static AppException _invalidSize() => const AppException(
    message: 'La imagen debe pesar como maximo 5 MiB.',
    code: 'move_media_size_invalid',
  );
}

class _ImageProcessingRequest {
  const _ImageProcessingRequest(
    this.bytes,
    this.fileName,
    this.maxOutputBytes,
    this.maxDimension,
  );

  final Uint8List bytes;
  final String fileName;
  final int maxOutputBytes;
  final int maxDimension;
}

PreparedMoveImage _processImage(_ImageProcessingRequest request) {
  final source = img.decodeImage(request.bytes);
  if (source == null) {
    throw const AppException(
      message: 'No pudimos procesar esta imagen.',
      code: 'move_media_decode_failed',
    );
  }
  var decoded = source;
  if (decoded.width * decoded.height > 40000000) {
    throw const AppException(
      message: 'La resolucion de la imagen es demasiado grande.',
      code: 'move_media_dimensions_invalid',
    );
  }

  decoded = img.bakeOrientation(decoded);
  final largestSide = math.max(decoded.width, decoded.height);
  if (largestSide > request.maxDimension) {
    final scale = request.maxDimension / largestSide;
    decoded = img.copyResize(
      decoded,
      width: math.max(1, (decoded.width * scale).round()),
      height: math.max(1, (decoded.height * scale).round()),
      interpolation: img.Interpolation.average,
    );
  }

  var quality = 88;
  var encoded = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
  while (encoded.length > request.maxOutputBytes && quality > 55) {
    quality -= 8;
    encoded = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
  }
  while (encoded.length > request.maxOutputBytes &&
      decoded.width > 640 &&
      decoded.height > 640) {
    decoded = img.copyResize(
      decoded,
      width: (decoded.width * 0.8).round(),
      height: (decoded.height * 0.8).round(),
      interpolation: img.Interpolation.average,
    );
    encoded = Uint8List.fromList(img.encodeJpg(decoded, quality: 65));
  }
  if (encoded.length > request.maxOutputBytes) {
    throw const AppException(
      message: 'No pudimos reducir la imagen por debajo de 5 MiB.',
      code: 'move_media_compression_failed',
    );
  }

  // Re-encode JPEG intentionally: no EXIF, GPS, comments or source metadata.
  return PreparedMoveImage(
    bytes: encoded,
    fileName: request.fileName,
    mimeType: 'image/jpeg',
  );
}
