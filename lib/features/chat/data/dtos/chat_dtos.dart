import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../../../../core/utils/display_formatters.dart';

ChatConversation conversationFromJson(Map<String, dynamic> json) {
  final type = '${json['type'] ?? json['conversationType'] ?? ''}';
  final participantCount =
      _nullableInt(json['participantCount']) ??
      _nullableInt(json['membersCount']) ??
      (json['participants'] is List
          ? (json['participants'] as List).length
          : null);

  return ChatConversation(
    id: '${json['id'] ?? json['conversationId'] ?? ''}',
    title: DisplayFormatters.chatTitle(
      rawTitle: (json['title'] ?? json['businessName'] ?? json['displayName'])
          ?.toString(),
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
        'businessName',
      ]),
      firstName: _optionalString(json, const [
        'peerFirstName',
        'otherFirstName',
      ]),
      lastName: _optionalString(json, const ['peerLastName', 'otherLastName']),
      conversationType: type,
      participantCount: participantCount,
    ),
    type: type.isEmpty ? 'Direct' : type,
    unreadCount: _int(
      json['unreadCount'] ??
          json['UnreadCount'] ??
          json['unread'] ??
          json['unreadMessages'],
    ),
    status: '${json['status'] ?? json['Status'] ?? 'Open'}',
    businessId: _nullableInt(json['businessId']),
    businessName: _optionalString(json, const [
      'businessName',
      'BusinessName',
      'merchantName',
    ]),
    businessLogoUrl: _optionalString(json, const [
      'businessLogoUrl',
      'logoUrl',
      'businessImageUrl',
    ]),
    avatarUrl: _optionalString(json, const ['avatarUrl', 'AvatarUrl']),
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
    peerPhotoUrl: _optionalString(json, const [
      'peerPhotoUrl',
      'peerAvatarUrl',
      'peerImageUrl',
      'otherPhotoUrl',
      'photoUrl',
    ]),
    participantCount: participantCount,
    lastMessage: _lastMessageBody(json),
    updatedAt: DateTime.tryParse(
      '${json['updatedAt'] ?? json['lastMessageAt'] ?? ''}',
    ),
  );
}

String? _lastMessageBody(Map<String, dynamic> json) {
  final direct = json['lastMessageBody'] ?? json['LastMessageBody'];
  if (direct != null && '$direct'.trim().isNotEmpty) return '$direct'.trim();

  final last = json['lastMessage'] ?? json['LastMessage'];
  if (last is Map) {
    final preview = _nonEmptyString(last['previewText'] ?? last['PreviewText']);
    if (preview != null) {
      return _withOwnPrefix(last, preview);
    }

    final body = _nonEmptyString(
      last['body'] ?? last['text'] ?? last['message'] ?? last['content'],
    );
    if (body != null) return _withOwnPrefix(last, body);

    final fromType = _previewFromMessageType(last);
    if (fromType != null) return _withOwnPrefix(last, fromType);
  }

  if (last is String && last.trim().isNotEmpty) return last.trim();
  return null;
}

String? _withOwnPrefix(Map<dynamic, dynamic> last, String text) {
  if (last['isOwnMessage'] == true && !text.toLowerCase().startsWith('tú:')) {
    return 'Tú: $text';
  }
  return text;
}

String? _previewFromMessageType(Map<dynamic, dynamic> last) {
  final type = '${last['messageType'] ?? last['type'] ?? ''}'.toLowerCase();
  if (type.isEmpty) return null;
  if (type.contains('image') || type.contains('photo')) {
    return '📷 Imagen';
  }
  if (type.contains('location') || type.contains('ubicacion')) {
    final address = _nonEmptyString(last['address'] ?? last['Address']);
    return address == null ? '📍 Ubicación' : '📍 $address';
  }
  if (type.contains('voice') || type.contains('audio')) {
    return '🎤 Nota de voz';
  }
  if (type.contains('file') || type.contains('document')) {
    return '📎 Archivo';
  }
  if (type.contains('payment') || type.contains('pago')) {
    return '💳 Pago';
  }
  return null;
}

String? _nonEmptyString(dynamic value) {
  if (value == null) return null;
  final trimmed = '$value'.trim();
  return trimmed.isEmpty ? null : trimmed;
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
  final updatedRaw = json['updatedAt'] ?? json['createdAt'] ?? json['sentAt'];
  return ChatMessage(
    id: '${json['id'] ?? json['messageId'] ?? ''}',
    body: json['body']?.toString() ?? json['text']?.toString() ?? '',
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
