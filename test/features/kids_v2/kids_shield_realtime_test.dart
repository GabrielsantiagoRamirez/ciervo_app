import 'dart:async';
import 'dart:math';

import 'package:ciervo_clud/core/result/result.dart';
import 'package:ciervo_clud/features/kids_v2/data/realtime/kids_realtime_controller.dart';
import 'package:ciervo_clud/features/kids_v2/data/repositories/kids_v2_repositories.dart';
import 'package:ciervo_clud/features/kids_v2/domain/models/kids_v2_models.dart';
import 'package:ciervo_clud/features/kids_v2/presentation/controllers/kids_shield_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Kids Shield', () {
    test('registra exactamente un intento cuando Shield rechaza', () async {
      final repository = _FakeKidsRepository(
        shield: const ShieldDecision(
          allowed: false,
          requiresApproval: false,
          ruleMatched: 'GEOFENCE',
          reason: 'Fuera de zona',
        ),
      );

      final result = await KidsShieldController(repository).validate('pay-1');

      expect(repository.securityAttempts, hasLength(1));
      result.when(
        success: (state) {
          expect(state.rejected, isTrue);
          expect(state.attemptRegistered, isTrue);
          expect(state.decision.ruleMatched, 'GEOFENCE');
        },
        failure: (error) => fail('$error'),
      );
    });

    test('no registra intento si requiere aprobación', () async {
      final repository = _FakeKidsRepository(
        shield: const ShieldDecision(
          allowed: false,
          requiresApproval: true,
          reason: 'Tutor requerido',
        ),
      );

      final result = await KidsShieldController(repository).validate('pay-2');

      expect(repository.securityAttempts, isEmpty);
      result.when(
        success: (state) => expect(state.rejected, isFalse),
        failure: (error) => fail('$error'),
      );
    });
  });

  group('Kids realtime', () {
    test('hace catch-up, deduplica y persiste cursor', () async {
      final live = StreamController<Result<KidsRealtimeEvent>>();
      final repository = _FakeRealtimeRepository(
        pages: [
          Success(
            KidsRealtimeEventPage(
              nextCursor: 2,
              hasMore: false,
              items: [_event(2), _event(1), _event(2)],
            ),
          ),
        ],
        live: live.stream,
      );
      final store = _MemoryCursorStore();
      final controller = KidsRealtimeController(
        repository: repository,
        cursorStore: store,
        random: Random(1),
      );
      final received = <int>[];
      final subscription = controller.events.listen(
        (event) => received.add(event.cursor),
      );

      await controller.start('pay-1');
      await _flush();

      expect(received, [1, 2]);
      expect(store.values['pay-1'], 2);
      expect(controller.state.phase, KidsRealtimePhase.live);

      await controller.stop();
      await live.close();
      await subscription.cancel();
      await controller.dispose();
    });

    test('usa polling real como fallback al quedar offline', () async {
      final live = StreamController<Result<KidsRealtimeEvent>>();
      final repository = _FakeRealtimeRepository(
        pages: [
          Failure(Exception('offline')),
          Success(
            KidsRealtimeEventPage(
              nextCursor: 3,
              hasMore: false,
              items: [_event(3)],
            ),
          ),
        ],
        live: live.stream,
      );
      final phases = <KidsRealtimePhase>[];
      final controller = KidsRealtimeController(
        repository: repository,
        cursorStore: _MemoryCursorStore(),
        delay: (_) async {},
        random: Random(2),
      );
      final subscription = controller.states.listen(
        (state) => phases.add(state.phase),
      );

      await controller.start('pay-offline');
      await _flush();

      expect(repository.pollCalls, greaterThanOrEqualTo(2));
      expect(phases, contains(KidsRealtimePhase.pollingFallback));
      expect(controller.state.cursor, 3);

      await controller.stop();
      await live.close();
      await subscription.cancel();
      await controller.dispose();
    });

    test('resume recupera desde el cursor persistido sin duplicar', () async {
      final firstLive = StreamController<Result<KidsRealtimeEvent>>();
      final repository = _FakeRealtimeRepository(
        pages: [
          Success(
            KidsRealtimeEventPage(
              nextCursor: 5,
              hasMore: false,
              items: [_event(5)],
            ),
          ),
          Success(
            KidsRealtimeEventPage(
              nextCursor: 6,
              hasMore: false,
              items: [_event(5), _event(6)],
            ),
          ),
        ],
        live: firstLive.stream.asBroadcastStream(),
      );
      final store = _MemoryCursorStore();
      final controller = KidsRealtimeController(
        repository: repository,
        cursorStore: store,
      );
      final received = <int>[];
      final subscription = controller.events.listen(
        (event) => received.add(event.cursor),
      );

      await controller.start('pay-resume');
      await _flush();
      await controller.pause();
      await controller.resume();
      await _flush();

      expect(received, [5, 6]);
      expect(repository.requestedCursors, containsAllInOrder([0, 5]));
      expect(store.values['pay-resume'], 6);

      await controller.stop();
      await firstLive.close();
      await subscription.cancel();
      await controller.dispose();
    });
  });
}

KidsRealtimeEvent _event(int cursor) => KidsRealtimeEvent(
  cursor: cursor,
  type: 'PAYMENT_UPDATED',
  createdAt: DateTime.utc(2026, 7, 18),
);

Future<void> _flush() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _MemoryCursorStore implements KidsRealtimeCursorStore {
  final values = <String, int>{};

  @override
  Future<int> read(String paymentSessionId) async =>
      values[paymentSessionId] ?? 0;

  @override
  Future<void> write(String paymentSessionId, int cursor) async {
    values[paymentSessionId] = cursor;
  }
}

class _FakeRealtimeRepository implements KidsRealtimeRepository {
  _FakeRealtimeRepository({required this.pages, required this.live});

  final List<Result<KidsRealtimeEventPage>> pages;
  final Stream<Result<KidsRealtimeEvent>> live;
  final requestedCursors = <int>[];
  int pollCalls = 0;

  @override
  Stream<Result<KidsRealtimeEvent>> connect(
    String paymentSessionId, {
    required int cursor,
  }) => live;

  @override
  Future<Result<KidsRealtimeEventPage>> poll(
    String paymentSessionId, {
    required int cursor,
    int take = 100,
  }) async {
    requestedCursors.add(cursor);
    final index = pollCalls.clamp(0, pages.length - 1);
    pollCalls++;
    return pages[index];
  }
}

class _FakeKidsRepository implements KidsRepository {
  _FakeKidsRepository({required this.shield});

  final ShieldDecision shield;
  final securityAttempts = <KidSecurityAttemptRequest>[];

  @override
  Future<Result<ShieldDecision>> validateShield(
    KidsRulesValidateRequest request,
  ) async => Success(shield);

  @override
  Future<Result<void>> registerSecurityAttempt(
    KidSecurityAttemptRequest request,
  ) async {
    securityAttempts.add(request);
    return const Success(null);
  }

  @override
  Future<Result<KidsPaymentStatusSnapshot>> approval(String id) async =>
      const Success(
        KidsPaymentStatusSnapshot(
          paymentSessionId: 'pay',
          status: 1,
          statusLabel: 'Pending',
          terminal: false,
        ),
      );

  @override
  Future<Result<void>> cancelPaymentRequest(int id) async =>
      const Success(null);

  @override
  Future<Result<KidsQrConfirmResponse>> confirmQr(
    KidsQrConfirmRequest request,
  ) async =>
      const Success(KidsQrConfirmResponse(paymentSessionId: 'pay', status: 1));

  @override
  Future<Result<KidsCommerceItem>> commerce(int commerceId) async =>
      Success(_commerce);

  @override
  Future<Result<PaymentRequest>> createPaymentRequest(
    PayForMeCommand command,
  ) => throw UnimplementedError();

  @override
  Future<Result<KidNfcStatus>> nfcStatus() async =>
      const Success(KidNfcStatus(enabled: false, status: 'pending'));

  @override
  Future<Result<KidProfile>> profile() => throw UnimplementedError();

  @override
  Future<Result<KidsCommerceItem>> readCommerceQr(
    CommerceQrReadRequest request,
  ) async => Success(_commerce);

  @override
  Future<Result<ReservationPolicy>> reservationPolicy(int commerceId) =>
      throw UnimplementedError();

  @override
  Future<Result<KidsQrScanResponse>> scanQr(KidsQrScanRequest request) =>
      throw UnimplementedError();

  @override
  Future<Result<List<KidsCommerceItem>>> searchCommerce({
    String? name,
    String? city,
    String? category,
  }) async => Success([_commerce]);

  @override
  Future<Result<List<PaymentRequest>>> sentPaymentRequests() async =>
      const Success([]);

  @override
  Future<Result<KidSettings>> settings() => throw UnimplementedError();

  @override
  Future<Result<KidsPaymentStatusSnapshot>> tracking(String id) async =>
      const Success(
        KidsPaymentStatusSnapshot(
          paymentSessionId: 'pay',
          status: 1,
          statusLabel: 'Pending',
          terminal: false,
        ),
      );

  @override
  Future<Result<KidsCommerceItem>> validateCommerceId(
    CommerceIdValidateRequest request,
  ) async => Success(_commerce);

  static const _commerce = KidsCommerceItem(
    commerceId: 1,
    name: 'Tienda',
    acceptsCiervoPayments: true,
    requiresReservation: false,
  );
}
