import 'package:flutter_test/flutter_test.dart';

import 'package:ciervo_clud/features/chat/data/dtos/chat_button_dto.dart';
import 'package:ciervo_clud/features/chat/domain/entities/chat_button.dart';

void main() {
  test('parses chat buttons from list response', () {
    final items = ChatButtonDto.listFrom([
      {
        'code': 'Pay',
        'label': 'Pagar',
        'visibility': 'ProductionReady',
        'sortOrder': 1,
      },
      {
        'code': 'Trips',
        'label': 'Viajes',
        'visibility': 'RequiresProvider',
      },
    ]);

    expect(items, hasLength(2));
    expect(items.first.toDomain().visibility, ChatButtonVisibility.productionReady);
    expect(items.last.toDomain().visibility, ChatButtonVisibility.requiresProvider);
    expect(items.last.toDomain().visibility.isVisible, isFalse);
  });

  test('disabled button stays visible but not enabled', () {
    final button = ChatButtonDto.fromJson({
      'code': 'Transport',
      'label': 'Transporte',
      'visibility': 'DisabledWithMessage',
      'message': 'Proximamente en tu pais',
    }).toDomain();

    expect(button.visibility.isVisible, isTrue);
    expect(button.visibility.isEnabled, isFalse);
    expect(button.message, 'Proximamente en tu pais');
  });
}
