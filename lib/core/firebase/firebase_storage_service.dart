import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseUploadResult {
  const FirebaseUploadResult({
    required this.downloadUrl,
    required this.storagePath,
    this.contentType,
  });

  final String downloadUrl;
  final String storagePath;
  final String? contentType;
}

class FirebaseStorageService {
  bool get isAvailable {
    if (Firebase.apps.isEmpty) return false;
    try {
      FirebaseStorage.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<FirebaseUploadResult?> uploadFile({
    required String storagePath,
    required String localPath,
    String? contentType,
  }) async {
    if (!isAvailable) return null;
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;
      final ref = FirebaseStorage.instance.ref(storagePath);
      final metadata = contentType == null
          ? null
          : SettableMetadata(contentType: contentType);
      await ref.putFile(file, metadata);
      final url = await ref.getDownloadURL();
      return FirebaseUploadResult(
        downloadUrl: url,
        storagePath: storagePath,
        contentType: contentType,
      );
    } catch (_) {
      return null;
    }
  }

  String profilePhotoPath(String userKey) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return 'users/$userKey/profile_$stamp.jpg';
  }

  String chatImagePath(String conversationId) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return 'chat/$conversationId/$stamp.jpg';
  }
}
