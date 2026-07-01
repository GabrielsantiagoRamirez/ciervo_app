import '../../../../core/di/service_locator.dart';
import '../../../../core/firebase/firebase_storage_service.dart';

class ChatImageUploader {
  const ChatImageUploader();

  Future<({
    String mediaUrl,
    String storagePath,
    String? mediaType,
  })?> uploadForConversation({
    required String conversationId,
    required String localPath,
    String? userId,
  }) async {
    final storage = getIt<FirebaseStorageService>();
    if (!storage.isAvailable) return null;

    final path = storage.chatImagePath(conversationId);
    final upload = await storage.uploadFile(
      storagePath: path,
      localPath: localPath,
      contentType: 'image/jpeg',
    );
    if (upload == null) return null;
    return (
      mediaUrl: upload.downloadUrl,
      storagePath: upload.storagePath,
      mediaType: upload.contentType ?? 'image/jpeg',
    );
  }
}
