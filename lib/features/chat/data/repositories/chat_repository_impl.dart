import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/chat_button.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../chat_image_uploader.dart';
import '../dtos/chat_button_dto.dart';
import '../dtos/chat_dtos.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._remote);
  final ChatRemoteDataSource _remote;

  @override
  Future<Result<List<ChatConversation>>> conversations() => _guard(
    () async => (await _remote.conversations())
        .whereType<Map<String, dynamic>>()
        .map(conversationFromJson)
        .toList(),
  );

  @override
  Future<Result<ChatConversation>> conversation(String id) =>
      _guard(() async => conversationFromJson(await _remote.conversation(id)));

  @override
  Future<Result<List<ChatMessage>>> messages(
    String id, {
    required int page,
    int pageSize = 50,
  }) => _guard(
    () async => (await _remote.messages(id, page, pageSize))
        .whereType<Map<String, dynamic>>()
        .map(messageFromJson)
        .toList()
        .reversed
        .toList(),
  );

  @override
  Future<Result<ChatConversation>> createBusinessConversation({
    required int businessId,
    required String title,
    int? reservationId,
    int? orderId,
  }) => _guard(
    () async => conversationFromJson(
      await _remote.createBusinessConversation(
        businessId: businessId,
        title: title,
        reservationId: reservationId,
        orderId: orderId,
      ),
    ),
  );

  @override
  Future<Result<ChatConversation>> createSupportConversation({
    required String title,
  }) => _guard(
    () async => conversationFromJson(
      await _remote.createSupportConversation(title: title),
    ),
  );

  @override
  Future<Result<ChatConversation>> createDirectConversation({
    required String targetUserId,
  }) => _guard(
    () async => conversationFromJson(
      await _remote.createDirectConversation(targetUserId: targetUserId),
    ),
  );

  @override
  Future<Result<ChatMessage>> forwardMessage({
    required String sourceConversationId,
    required String messageId,
    required String targetConversationId,
    String? comment,
  }) => _guard(
    () async => messageFromJson(
      await _remote.forwardMessage(
        conversationId: sourceConversationId,
        messageId: messageId,
        targetConversationId: targetConversationId,
        comment: comment,
      ),
    ),
  );

  @override
  Future<Result<ChatMessage>> sendText(String id, String body) =>
      _guard(() async => messageFromJson(await _remote.sendText(id, body)));

  @override
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
  }) => _guard(
    () async => messageFromJson(
      await _remote.sendTypedMessage(
        id,
        messageType: messageType,
        body: body,
        metadataJson: metadataJson,
        attachmentUrl: attachmentUrl,
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        storagePath: storagePath,
        mediaType: mediaType,
      ),
    ),
  );

  @override
  Future<Result<ChatMessage>> sendMedia(String id, String path, String fileName) =>
      _guard(() async {
        final uploaded = await const ChatImageUploader().uploadForConversation(
          conversationId: id,
          localPath: path,
        );
        if (uploaded != null) {
          return messageFromJson(
            await _remote.sendTypedMessage(
              id,
              messageType: 'Image',
              body: '',
              mediaUrl: uploaded.mediaUrl,
              storagePath: uploaded.storagePath,
              mediaType: uploaded.mediaType,
              attachmentUrl: uploaded.mediaUrl,
            ),
          );
        }
        return messageFromJson(await _remote.sendMedia(id, path, fileName));
      });

  @override
  Future<Result<void>> markAsRead(String id) => _guard(() async {
        await _remote.markAsRead(id);
      });

  @override
  Future<Result<List<ChatButton>>> buttons() => _guard(() async {
        final raw = await _remote.buttons();
        return ChatButtonDto.listFrom(raw)
            .map((dto) => dto.toDomain())
            .where((button) => button.isVisibleOnMobile)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}
