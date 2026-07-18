import 'package:ciervo_clud/features/movie/domain/models/movie_commands.dart';
import 'package:ciervo_clud/features/movie/domain/models/movie_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('modelos Movie tolerantes', () {
    test('acepta números/string y conserva enums desconocidos', () {
      final seat = MovieSeat.fromJson({
        'seatId': 12,
        'code': 'A1',
        'row': 'A',
        'number': '1',
        'type': 99,
        'price': '15000.50',
        'available': 1,
      });

      expect(seat.seatId, '12');
      expect(seat.number, 1);
      expect(seat.type, CinemaSeatType.unknown);
      expect(seat.price, 15000.5);
      expect(seat.available, isTrue);
    });

    test('payloadJson inválido no rompe el evento', () {
      final invalid = MovieEvent.fromJson({
        'cursor': 2,
        'eventType': 'Changed',
        'payloadJson': '{mal',
      });
      final valid = MovieEvent.fromJson({
        'cursor': 3,
        'eventType': 'Changed',
        'payloadJson': '{"status":4}',
      });

      expect(invalid.payload, isNull);
      expect(valid.payload, {'status': 4});
    });
  });

  group('comandos exactos', () {
    test('pago solo serializa Wallet=1 e idempotencia en body', () {
      final json = PayMovieReservationCommand(
        idempotencyKey: 'wallet-retry-0001',
      ).toJson();

      expect(json['paymentMethod'], 1);
      expect(json['idempotencyKey'], 'wallet-retry-0001');
      expect(json, isNot(contains('Idempotency-Key')));
    });

    test('selección por códigos no mezcla IDs', () {
      final json = SelectMovieSeatsCommand.byCodes(['A1', 'A2']).toJson();

      expect(json['codes'], ['A1', 'A2']);
      expect(json['showtimeSeatIds'], isEmpty);
    });

    test('rechaza asientos duplicados y claves cortas', () {
      expect(
        () => SelectMovieSeatsCommand.byCodes(['A1', 'a1']),
        throwsArgumentError,
      );
      expect(
        () => PayMovieReservationCommand(idempotencyKey: 'short'),
        throwsArgumentError,
      );
    });

    test('request usa nombres canónicos plurales del contrato', () {
      final json = CreateMovieRequestCommand(
        conversationId: 44,
        showtimeId: '33333333-3333-3333-3333-333333333333',
        ticketCount: 2,
        idempotencyKey: 'movie-request-install-0001',
      ).toJson();

      expect(json['conversationId'], 44);
      expect(json['ticketCount'], 2);
      expect(json['showtimeId'], startsWith('33333333'));
    });
  });
}
