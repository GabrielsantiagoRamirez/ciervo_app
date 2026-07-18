import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/auth_tokens.dart';
import '../../../../core/session/session_manager.dart';
import '../../domain/models/kids_v2_models.dart';
import '../datasources/kids_v2_remote_datasource.dart';

abstract interface class KidSessionStore {
  Future<void> replace(KidSession session, {required String deviceId});
  Future<void> clear();
}

class SessionManagerKidSessionStore implements KidSessionStore {
  const SessionManagerKidSessionStore(this._sessionManager);
  final SessionManager _sessionManager;

  @override
  Future<void> replace(KidSession session, {required String deviceId}) =>
      _sessionManager.saveTokens(
        AuthTokens(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
          refreshPath: '/api/v1/kids/auth/refresh',
          deviceId: deviceId,
        ),
      );

  @override
  Future<void> clear() => _sessionManager.clear();
}

abstract interface class KidsAuthRepository {
  Future<Result<KidSession>> login(KidLoginCommand command);
  Future<Result<KidSession>> refresh(KidRefreshCommand command);
  Future<Result<void>> logout();
}

class KidsAuthRepositoryImpl implements KidsAuthRepository {
  const KidsAuthRepositoryImpl(this._remote, this._store);
  final KidsV2RemoteDataSource _remote;
  final KidSessionStore _store;

  @override
  Future<Result<KidSession>> login(KidLoginCommand command) =>
      _guardSession(() => _remote.login(command), deviceId: command.deviceId);

  @override
  Future<Result<KidSession>> refresh(KidRefreshCommand command) =>
      _guardSession(
        () => _remote.refresh(command),
        deviceId: command.deviceId,
        clearOnFailure: true,
      );

  @override
  Future<Result<void>> logout() async {
    try {
      await _store.clear();
      return const Success(null);
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  Future<Result<KidSession>> _guardSession(
    Future<KidSession> Function() run, {
    required String deviceId,
    bool clearOnFailure = false,
  }) async {
    try {
      final session = await run();
      await _store.replace(session, deviceId: deviceId);
      return Success(session);
    } catch (error) {
      if (clearOnFailure) {
        try {
          await _store.clear();
        } catch (_) {
          // Conserva el error original de refresh.
        }
      }
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}

abstract interface class KidsRepository {
  Future<Result<KidProfile>> profile();
  Future<Result<KidSettings>> settings();
  Future<Result<KidNfcStatus>> nfcStatus();
  Future<Result<List<KidsCommerceItem>>> searchCommerce({
    String? name,
    String? city,
    String? category,
  });
  Future<Result<KidsCommerceItem>> commerce(int commerceId);
  Future<Result<KidsCommerceItem>> readCommerceQr(
    CommerceQrReadRequest request,
  );
  Future<Result<KidsCommerceItem>> validateCommerceId(
    CommerceIdValidateRequest request,
  );
  Future<Result<ReservationPolicy>> reservationPolicy(int commerceId);
  Future<Result<ShieldDecision>> validateShield(
    KidsRulesValidateRequest request,
  );
  Future<Result<void>> registerSecurityAttempt(
    KidSecurityAttemptRequest request,
  );
  Future<Result<PaymentRequest>> createPaymentRequest(PayForMeCommand command);
  Future<Result<List<PaymentRequest>>> sentPaymentRequests();
  Future<Result<void>> cancelPaymentRequest(int id);
  Future<Result<KidsQrScanResponse>> scanQr(KidsQrScanRequest request);
  Future<Result<KidsQrConfirmResponse>> confirmQr(KidsQrConfirmRequest request);
  Future<Result<KidsPaymentStatusSnapshot>> tracking(String paymentSessionId);
  Future<Result<KidsPaymentStatusSnapshot>> approval(String paymentSessionId);
}

class KidsRepositoryImpl implements KidsRepository {
  const KidsRepositoryImpl(this._remote);
  final KidsV2RemoteDataSource _remote;

  @override
  Future<Result<KidProfile>> profile() => _guard(_remote.profile);
  @override
  Future<Result<KidSettings>> settings() => _guard(_remote.settings);
  @override
  Future<Result<KidNfcStatus>> nfcStatus() => _guard(_remote.nfcStatus);
  @override
  Future<Result<List<KidsCommerceItem>>> searchCommerce({
    String? name,
    String? city,
    String? category,
  }) => _guard(
    () => _remote.searchCommerce(name: name, city: city, category: category),
  );
  @override
  Future<Result<KidsCommerceItem>> commerce(int commerceId) =>
      _guard(() => _remote.commerce(commerceId));
  @override
  Future<Result<KidsCommerceItem>> readCommerceQr(
    CommerceQrReadRequest request,
  ) => _guard(() => _remote.readCommerceQr(request));
  @override
  Future<Result<KidsCommerceItem>> validateCommerceId(
    CommerceIdValidateRequest request,
  ) => _guard(() => _remote.validateCommerceId(request));
  @override
  Future<Result<ReservationPolicy>> reservationPolicy(int commerceId) =>
      _guard(() => _remote.reservationPolicy(commerceId));
  @override
  Future<Result<ShieldDecision>> validateShield(
    KidsRulesValidateRequest request,
  ) => _guard(() => _remote.validateShield(request));
  @override
  Future<Result<void>> registerSecurityAttempt(
    KidSecurityAttemptRequest request,
  ) => _guard(() => _remote.registerSecurityAttempt(request));
  @override
  Future<Result<PaymentRequest>> createPaymentRequest(
    PayForMeCommand command,
  ) => _guard(() => _remote.createPaymentRequest(command));
  @override
  Future<Result<List<PaymentRequest>>> sentPaymentRequests() =>
      _guard(_remote.sentPaymentRequests);
  @override
  Future<Result<void>> cancelPaymentRequest(int id) =>
      _guard(() => _remote.cancelPaymentRequest(id));
  @override
  Future<Result<KidsQrScanResponse>> scanQr(KidsQrScanRequest request) =>
      _guard(() => _remote.scanQr(request));
  @override
  Future<Result<KidsQrConfirmResponse>> confirmQr(
    KidsQrConfirmRequest request,
  ) => _guard(() => _remote.confirmQr(request));
  @override
  Future<Result<KidsPaymentStatusSnapshot>> tracking(String paymentSessionId) =>
      _guard(() => _remote.tracking(paymentSessionId));
  @override
  Future<Result<KidsPaymentStatusSnapshot>> approval(String paymentSessionId) =>
      _guard(() => _remote.approval(paymentSessionId));

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Success(await run());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}

abstract interface class KidsRealtimeRepository {
  Future<Result<KidsRealtimeEventPage>> poll(
    String paymentSessionId, {
    required int cursor,
    int take,
  });
  Stream<Result<KidsRealtimeEvent>> connect(
    String paymentSessionId, {
    required int cursor,
  });
}

class KidsRealtimeRepositoryImpl implements KidsRealtimeRepository {
  const KidsRealtimeRepositoryImpl(this._remote);
  final KidsV2RemoteDataSource _remote;

  @override
  Future<Result<KidsRealtimeEventPage>> poll(
    String paymentSessionId, {
    required int cursor,
    int take = 100,
  }) async {
    try {
      return Success(
        await _remote.pollEvents(paymentSessionId, cursor: cursor, take: take),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Stream<Result<KidsRealtimeEvent>> connect(
    String paymentSessionId, {
    required int cursor,
  }) async* {
    try {
      await for (final event in _remote.streamEvents(
        paymentSessionId,
        cursor: cursor,
      )) {
        yield Success(event);
      }
    } catch (error) {
      yield Failure(ErrorMapper.fromObject(error));
    }
  }
}
