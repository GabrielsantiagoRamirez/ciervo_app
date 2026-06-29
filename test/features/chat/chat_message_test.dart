import 'package:ciervo_clud/features/chat/domain/entities/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses booking receipt only for System booking_receipt messages', () {
    const message = ChatMessage(
      id: '12',
      body: 'Reserva creada',
      messageType: 'System',
      isMine: false,
      metadataJson: '''
{"type":"booking_receipt","booking":{"publicCode":"RSV-C14262FB","business":"Club","client":"Will","bookingDate":"2026-06-23T23:44:47Z","bookingType":"Table","status":"Pending","total":300000,"currency":"COP"}}
''',
    );

    expect(message.bookingReceipt?.publicCode, 'RSV-C14262FB');
    expect(message.bookingReceipt?.total, 300000);
  });

  test('ignores malformed or unrelated metadata', () {
    const malformed = ChatMessage(
      id: '1',
      body: 'hola',
      messageType: 'System',
      isMine: false,
      metadataJson: '{bad',
    );
    const text = ChatMessage(
      id: '2',
      body: 'hola',
      messageType: 'Text',
      isMine: false,
      metadataJson: '{"type":"booking_receipt","booking":{}}',
    );
    expect(malformed.bookingReceipt, isNull);
    expect(text.bookingReceipt, isNull);
  });
}
