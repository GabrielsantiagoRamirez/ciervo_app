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

ChatMessage messageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: '${json['id'] ?? json['messageId'] ?? ''}',
  body: json['body']?.toString() ?? '',
  messageType: '${json['messageType'] ?? 'Text'}',
  isMine: json['isOwnMessage'] == true,
  senderName: json['senderRole']?.toString(),
  sentAt: DateTime.tryParse('${json['sentAt'] ?? json['createdAt'] ?? ''}'),
  attachmentUrl:
      (json['attachmentMediaId'] ?? json['mediaId'] ?? json['attachmentUrl'])
          ?.toString(),
  metadataJson: json['metadataJson']?.toString(),
);

int _int(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
int? _nullableInt(dynamic value) =>
    value is int ? value : int.tryParse('$value');
