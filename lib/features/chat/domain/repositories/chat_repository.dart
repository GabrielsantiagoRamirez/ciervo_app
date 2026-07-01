import '../../../../core/result/result.dart';
import '../entities/chat_button.dart';
import '../entities/chat_conversation.dart';
import '../entities/chat_message.dart';

abstract interface class ChatRepository {
  Future<Result<List<ChatConversation>>> conversations();
  Future<Result<ChatConversation>> conversation(String id);
  Future<Result<List<ChatMessage>>> messages(
    String id, {
    required int page,
    int pageSize = 50,
  });
  Future<Result<ChatConversation>> createBusinessConversation({
    required int businessId,
    required String title,
    int? reservationId,
    int? orderId,
  });
  Future<Result<ChatConversation>> createSupportConversation({
    required String title,
  });
  Future<Result<ChatConversation>> createDirectConversation({
    required String targetUserId,
  });
  Future<Result<ChatMessage>> forwardMessage({
    required String sourceConversationId,
    required String messageId,
    required String targetConversationId,
    String? comment,
  });
  Future<Result<ChatMessage>> sendText(String id, String body);
  Future<Result<ChatMessage>> sendMedia(String id, String path, String fileName);
  Future<Result<ChatMessage>> sendTypedMessage(
    String id, {
    required String messageType,
    String? body,
    String? metadataJson,
    String? attachmentUrl,
    String? mediaUrl,
    String? thumbnailUrl,
    String? storagePath,
    String? mediaType,
  });
  Future<Result<List<ChatButton>>> buttons();
  Future<Result<void>> markAsRead(String id);
}
