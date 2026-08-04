import 'package:ciervo_clud/features/chat/data/dtos/chat_dtos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conversationFromJson usa lastMessage.previewText en la fila', () {
    final conversation = conversationFromJson({
      'id': 12,
      'title': 'Carlos',
      'type': 'Direct',
      'lastMessageAt': '2026-08-02T20:00:00Z',
      'unreadCount': 2,
      'lastMessage': {
        'id': 101,
        'senderName': 'Carlos Nossa',
        'isOwnMessage': false,
        'messageType': 'Image',
        'body': null,
        'previewText': '📷 Imagen',
        'mediaUrl': 'https://example.com/a.jpg',
      },
    });

    expect(conversation.lastMessage, '📷 Imagen');
    expect(conversation.unreadCount, 2);
  });

  test('conversationFromJson antepone Tú: si isOwnMessage', () {
    final conversation = conversationFromJson({
      'id': 1,
      'title': 'Ana',
      'type': 'Direct',
      'lastMessage': {
        'previewText': 'Hola',
        'isOwnMessage': true,
        'messageType': 'Text',
      },
    });

    expect(conversation.lastMessage, 'Tú: Hola');
  });

  test('conversationFromJson deriva preview desde messageType sin body', () {
    final conversation = conversationFromJson({
      'id': 2,
      'title': 'Hotel',
      'type': 'Business',
      'lastMessage': {'messageType': 'Location', 'body': null},
    });

    expect(conversation.lastMessage, '📍 Ubicación');
  });

  test('Direct usa avatarUrl / peerPhotoUrl en el círculo', () {
    final conversation = conversationFromJson({
      'id': 12,
      'type': 'Direct',
      'peerUserId': 2,
      'peerDisplayName': 'Carlos Nossa',
      'peerPhotoUrl': 'https://cdn.example/peer.jpg',
      'avatarUrl': 'https://cdn.example/avatar.jpg',
    });

    expect(conversation.peerDisplayName, 'Carlos Nossa');
    expect(conversation.peerPhotoUrl, 'https://cdn.example/peer.jpg');
    expect(conversation.avatarUrl, 'https://cdn.example/avatar.jpg');
    expect(conversation.circleImageUrl, 'https://cdn.example/avatar.jpg');
  });

  test('Business usa logo del negocio si no hay avatarUrl', () {
    final conversation = conversationFromJson({
      'id': 3,
      'type': 'Business',
      'businessId': 10,
      'businessName': 'Hotel Dorado',
      'businessLogoUrl': 'https://cdn.example/logo.png',
      'logoUrl': 'https://cdn.example/logo-alt.png',
    });

    expect(conversation.businessLogoUrl, 'https://cdn.example/logo.png');
    expect(conversation.circleImageUrl, 'https://cdn.example/logo.png');
  });

  test('Direct sin avatarUrl cae a peerPhotoUrl', () {
    final conversation = conversationFromJson({
      'id': 4,
      'type': 'Direct',
      'peerPhotoUrl': 'https://cdn.example/only-peer.jpg',
    });

    expect(conversation.circleImageUrl, 'https://cdn.example/only-peer.jpg');
  });
}
