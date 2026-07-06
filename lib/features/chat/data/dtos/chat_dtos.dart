import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../../../../core/utils/display_formatters.dart';

ChatConversation conversationFromJson(Map<String, dynamic> json) {
  final type = '${json['type'] ?? json['conversationType'] ?? ''}';
  final participantCount = _nullableInt(json['participantCount']) ??
      _nullableInt(json['membersCount']) ??
      (json['participants'] is List
          ? (json['participants'] as List).length
          : null);

  return ChatConversation(
    id: '${json['id'] ?? json['conversationId'] ?? ''}',
    title: DisplayFormatters.chatTitle(
      rawTitle: (json['title'] ?? json['displayName'])?.toString(),
      username: _optionalString(json, const [
        'peerUsername',
        'username',
        'otherUsername',
      ]),
      displayName: _optionalString(json, const [
        'peerDisplayName',
        'peerFullName',
        'peerName',
        'otherDisplayName',
      ]),
      firstName: _optionalString(json, const ['peerFirstName', 'otherFirstName']),
      lastName: _optionalString(json, const ['peerLastName', 'otherLastName']),
      conversationType: type,
      participantCount: participantCount,
    ),
    type: type,
    unreadCount: _int(json['unreadCount']),
    status: '${json['status'] ?? 'Open'}',
    businessId: _nullableInt(json['businessId']),
    peerUserId: _nullableInt(json['peerUserId']),
    peerUsername: _optionalString(json, const [
      'peerUsername',
      'username',
      'otherUsername',
    ]),
    peerDisplayName: _optionalString(json, const [
      'peerDisplayName',
      'peerFullName',
      'peerName',
    ]),
    participantCount: participantCount,
    lastMessage: (json['lastMessageBody'] ?? json['lastMessage']?['body'])
        ?.toString(),
    updatedAt: DateTime.tryParse(
      '${json['updatedAt'] ?? json['lastMessageAt'] ?? ''}',
    ),
  );
}

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
      final text = value.toString().trim();
      if (text.toLowerCase() != 'null') return text;
    }
  }
  return null;
}

int _int(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
int? _nullableInt(dynamic value) =>
    value is int ? value : int.tryParse('$value');
