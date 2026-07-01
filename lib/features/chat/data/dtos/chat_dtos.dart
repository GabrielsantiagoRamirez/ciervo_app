import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';

ChatConversation conversationFromJson(Map<String, dynamic> json) =>
    ChatConversation(
      id: '${json['id'] ?? json['conversationId'] ?? ''}',
      title:
          (json['title'] ?? json['displayName'])
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
              true
          ? (json['title'] ?? json['displayName']).toString()
          : 'Conversacion',
      type: '${json['type'] ?? json['conversationType'] ?? ''}',
      unreadCount: _int(json['unreadCount']),
      status: '${json['status'] ?? 'Open'}',
      businessId: _nullableInt(json['businessId']),
      lastMessage: (json['lastMessageBody'] ?? json['lastMessage']?['body'])
          ?.toString(),
      updatedAt: DateTime.tryParse(
        '${json['updatedAt'] ?? json['lastMessageAt'] ?? ''}',
      ),
    );

ChatMessage messageFromJson(Map<String, dynamic> json) {
  final mediaUrl = _optionalString(json, const [
    'mediaUrl',
    'imageUrl',
    'MediaUrl',
  ]);
  final attachment = _optionalString(json, const [
    'attachmentMediaId',
    'mediaId',
    'attachmentUrl',
  ]);
  final updatedRaw =
      json['updatedAt'] ?? json['createdAt'] ?? json['sentAt'];
  return ChatMessage(
    id: '${json['id'] ?? json['messageId'] ?? ''}',
    body: json['body']?.toString() ?? '',
    messageType: '${json['messageType'] ?? json['type'] ?? 'Text'}',
    isMine: json['isOwnMessage'] == true,
    senderName: json['senderRole']?.toString(),
    sentAt: DateTime.tryParse('${json['sentAt'] ?? json['createdAt'] ?? ''}'),
    attachmentUrl: attachment ?? mediaUrl,
    mediaUrl: mediaUrl ?? attachment,
    thumbnailUrl: _optionalString(json, const ['thumbnailUrl', 'ThumbnailUrl']),
    storagePath: _optionalString(json, const ['storagePath', 'StoragePath']),
    mediaUpdatedAt: DateTime.tryParse('$updatedRaw'),
    metadataJson: json['metadataJson']?.toString(),
  );
}

String? _optionalString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) {
      return value.toString();
    }
  }
  return null;
}

int _int(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
int? _nullableInt(dynamic value) =>
    value is int ? value : int.tryParse('$value');
