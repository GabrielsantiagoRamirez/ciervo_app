import 'dart:typed_data';

typedef MoveUploadProgress = void Function(int sentBytes, int totalBytes);

class PreparedMoveImage {
  const PreparedMoveImage({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

class MoveMediaAsset {
  const MoveMediaAsset({
    required this.id,
    this.fileName,
    this.contentType,
    this.sizeBytes,
  });

  factory MoveMediaAsset.fromJson(Map<String, dynamic> json) {
    final id = int.tryParse('${json['id'] ?? json['mediaId'] ?? ''}');
    if (id == null || id <= 0) {
      throw const FormatException('MediaAsset sin id valido.');
    }
    return MoveMediaAsset(
      id: id,
      fileName: json['fileName']?.toString(),
      contentType:
          json['contentType']?.toString() ?? json['mimeType']?.toString(),
      sizeBytes: int.tryParse('${json['sizeBytes'] ?? ''}'),
    );
  }

  final int id;
  final String? fileName;
  final String? contentType;
  final int? sizeBytes;
}

class MoveMediaDownload {
  const MoveMediaDownload({
    required this.bytes,
    this.contentType,
    this.fileName,
  });

  final Uint8List bytes;
  final String? contentType;
  final String? fileName;
}

class MoveOrphanCleanupResult {
  const MoveOrphanCleanupResult({required this.deleted, required this.failed});

  final List<MoveMediaAsset> deleted;
  final List<MoveMediaAsset> failed;
}
