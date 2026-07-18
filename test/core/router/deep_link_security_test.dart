import 'package:ciervo_clud/core/notifications/notification_deep_link_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normaliza deep links sensibles a rutas GoRouter', () {
    expect(
      NotificationDeepLinkParser.parse('ciervo://movie/request/req-1'),
      '/movie-requests/req-1',
    );
    expect(
      NotificationDeepLinkParser.parse(
        'https://app.ciervo.club/app/movie/qr/res-1',
      ),
      '/movie/qr/res-1',
    );
    expect(
      NotificationDeepLinkParser.parse('ciervo://kids/device/42'),
      '/master/kids/42/devices',
    );
    expect(
      NotificationDeepLinkParser.parse('ciervo://kids/request/request-7'),
      '/master/payment-requests',
    );
  });

  test('Movie QR no se normaliza al hub QR genérico', () {
    expect(
      NotificationDeepLinkParser.parse('/movie/qr/reservation-9'),
      '/movie/qr/reservation-9',
    );
    expect(NotificationDeepLinkParser.parse('/qr/reservation-9'), isNull);
  });

  test('rechaza query, rutas ambiguas y traversal codificado', () {
    expect(
      NotificationDeepLinkParser.parse('/movie/qr/id?redirect=/wallet'),
      isNull,
    );
    expect(NotificationDeepLinkParser.parse('/profile/chat/123'), isNull);
    expect(NotificationDeepLinkParser.parse('/kids/device/%2e%2e'), isNull);
  });
}
