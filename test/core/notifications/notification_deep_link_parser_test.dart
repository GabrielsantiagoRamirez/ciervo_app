import 'package:ciervo_clud/core/notifications/notification_deep_link_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('acepta rutas internas y hosts Ciervo explícitos', () {
    expect(NotificationDeepLinkParser.parse('/chat/123'), '/chat/123');
    expect(
      NotificationDeepLinkParser.parse('/promotions/5'),
      '/marketplace/promos/5',
    );
    expect(
      NotificationDeepLinkParser.parse('/marketplace/stores/10'),
      '/marketplace/stores/10',
    );
    expect(
      NotificationDeepLinkParser.parse('ciervo://reservations/abc-123'),
      '/reservations/abc-123',
    );
    expect(
      NotificationDeepLinkParser.parse(
        'https://app.ciervo.club/app/wallet/payment-request',
      ),
      '/wallet/payment-request',
    );
  });

  test('rechaza esquemas, hosts y traversal no confiables', () {
    expect(
      NotificationDeepLinkParser.parse('https://evil.example/chat/123'),
      isNull,
    );
    expect(NotificationDeepLinkParser.parse('javascript:alert(1)'), isNull);
    expect(NotificationDeepLinkParser.parse('/chat/%2e%2e/wallet'), isNull);
    expect(NotificationDeepLinkParser.parse('/unknown/123'), isNull);
  });

  test('solo acepta etapas conocidas del onboarding MOVE Driver', () {
    expect(
      NotificationDeepLinkParser.parse(
        'https://app.ciervo.club/app/move/driver/onboarding/status',
      ),
      '/move/driver/onboarding/status',
    );
    expect(
      NotificationDeepLinkParser.parse('/move/driver/onboarding/admin'),
      isNull,
    );
    expect(
      NotificationDeepLinkParser.parse('/move/driver/onboarding/status/25'),
      isNull,
    );
  });
}
