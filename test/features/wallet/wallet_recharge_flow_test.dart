import 'dart:convert';
import 'dart:typed_data';

import 'package:ciervo_clud/core/config/app_config.dart';
import 'package:ciervo_clud/core/config/app_environment.dart';
import 'package:ciervo_clud/core/network/auth_token_refresher.dart';
import 'package:ciervo_clud/core/network/network_client.dart';
import 'package:ciervo_clud/core/result/result.dart';
import 'package:ciervo_clud/core/session/session_manager.dart';
import 'package:ciervo_clud/core/storage/secure_storage.dart';
import 'package:ciervo_clud/features/profile/domain/entities/user_profile.dart';
import 'package:ciervo_clud/features/profile/domain/repositories/profile_repository.dart';
import 'package:ciervo_clud/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:ciervo_clud/features/wallet/data/dtos/wallet_operation_dtos.dart';
import 'package:ciervo_clud/features/wallet/data/models/wallet_recharge_session.dart';
import 'package:ciervo_clud/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:ciervo_clud/features/wallet/data/stores/wallet_recharge_session_store.dart';
import 'package:ciervo_clud/features/wallet/domain/entities/recharge_intent.dart';
import 'package:ciervo_clud/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:ciervo_clud/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('contrato HTTP de recarga', () {
    test('POST crea con body exacto y GET/sync usan intentId', () async {
      final adapter = _RechargeAdapter();
      final source = DioWalletRemoteDataSource(_client(adapter));

      final created = await source.createRechargeIntent(
        'card-7',
        25000,
        currency: 'CLP',
        idempotencyKey: '00000000-0000-4000-8000-000000000001',
        description: 'Recarga CIERVO Wallet',
      );
      await source.rechargeIntent(created.id);
      await source.syncRechargeIntent(created.id);

      expect(adapter.requests[0].method, 'POST');
      expect(
        adapter.requests[0].path,
        '/api/wallet/cards/card-7/recharge-intents',
      );
      expect(adapter.requests[0].data, {
        'amount': 25000.0,
        'currency': 'CLP',
        'idempotencyKey': '00000000-0000-4000-8000-000000000001',
        'description': 'Recarga CIERVO Wallet',
      });
      expect(
        adapter.requests.map((request) => request.path),
        containsAll([
          '/api/wallet/recharge-intents/intent-1',
          '/api/wallet/recharge-intents/intent-1/sync',
        ]),
      );
      expect(adapter.requests[2].method, 'POST');
      expect(created.checkoutUrl, 'https://www.mercadopago.cl/checkout');
    });
  });

  group('repositorio de recarga', () {
    test('CL deriva CLP, valida .cl y persiste todos los campos', () async {
      final storage = _MemoryStorage();
      final remote = _FakeRemote(
        checkoutUrl: 'https://checkout.mercadopago.cl/pay',
      );
      final repository = WalletRepositoryImpl(
        remote,
        _FakeProfileRepository('CL'),
        WalletRechargeSessionStore(storage),
        uuid: () => '00000000-0000-4000-8000-000000000001',
      );

      final result = await repository.createRechargeIntent(
        cardId: 'card-cl',
        amount: 10000,
        currency: 'COP',
      );

      expect(result, isA<Success<RechargeIntent>>());
      expect(remote.currency, 'CLP');
      expect(remote.description, 'Recarga CIERVO Wallet');
      final session = await WalletRechargeSessionStore(storage).read();
      expect(session?.intentId, 'intent-1');
      expect(session?.preferenceId, 'pref-1');
      expect(session?.countryCode, 'CL');
      expect(session?.currency, 'CLP');
      expect(session?.amount, 10000);
      expect(session?.cardId, 'card-cl');
      expect(session?.idempotencyKey, '00000000-0000-4000-8000-000000000001');
    });

    test(
      'CO deriva COP y una creación con otro monto usa clave nueva',
      () async {
        var sequence = 0;
        final remote = _FakeRemote(
          checkoutUrl: 'https://www.mercadopago.com.co/pay',
        );
        final repository = WalletRepositoryImpl(
          remote,
          _FakeProfileRepository('CO'),
          WalletRechargeSessionStore(_MemoryStorage()),
          uuid: () => '00000000-0000-4000-8000-00000000000${++sequence}',
        );

        await repository.createRechargeIntent(cardId: 'card', amount: 1000);
        await repository.createRechargeIntent(cardId: 'card', amount: 2000);

        expect(remote.currencies, ['COP', 'COP']);
        expect(remote.keys[0], isNot(remote.keys[1]));
      },
    );

    test('host de otro país falla y no persiste', () async {
      final storage = _MemoryStorage();
      final repository = WalletRepositoryImpl(
        _FakeRemote(checkoutUrl: 'https://www.mercadopago.com.co/pay'),
        _FakeProfileRepository('CL'),
        WalletRechargeSessionStore(storage),
      );

      final result = await repository.createRechargeIntent(
        cardId: 'card',
        amount: 1000,
      );

      expect(result, isA<Failure<RechargeIntent>>());
      expect(await WalletRechargeSessionStore(storage).read(), isNull);
    });
  });

  test('store sobrevive reinicio y limpia sesión incompatible', () async {
    final storage = _MemoryStorage();
    final firstStore = WalletRechargeSessionStore(storage);
    await firstStore.write(_session(amount: 1000));

    final afterRestart = WalletRechargeSessionStore(storage);
    expect((await afterRestart.read())?.intentId, 'intent');
    expect(
      await afterRestart.readCompatible(
        currency: 'COP',
        countryCode: 'CO',
        amount: 2000,
        cardId: 'card',
      ),
      isNull,
    );
    expect(await afterRestart.read(), isNull);
  });

  test('validación acepta solo HTTPS del host país o subdominio', () {
    const cl = RechargeIntent(
      id: 'i',
      checkoutUrl: 'https://sub.mercadopago.cl/pay',
      status: 'pending',
    );
    const spoofed = RechargeIntent(
      id: 'i',
      checkoutUrl: 'https://mercadopago.cl.evil.test/pay',
      status: 'pending',
    );
    expect(cl.isCheckoutHostAllowedFor('CL'), isTrue);
    expect(cl.isCheckoutHostAllowedFor('CO'), isFalse);
    expect(spoofed.isCheckoutHostAllowedFor('CL'), isFalse);
  });

  test('cubit sincroniza por intentId sin consultar config', () async {
    final repository = _CubitRepository();
    final cubit = WalletCubit(repository);

    await cubit.syncRechargeIntent('intent-fresh');

    expect(repository.syncedIntentId, 'intent-fresh');
    expect(repository.configCalls, 0);
    expect(cubit.state.rechargeIntent?.id, 'intent-fresh');
    await cubit.close();
  });
}

WalletRechargeSession _session({required double amount}) {
  return WalletRechargeSession(
    intentId: 'intent',
    preferenceId: 'pref',
    checkoutUrl: 'https://www.mercadopago.com.co/pay',
    currency: 'COP',
    countryCode: 'CO',
    idempotencyKey: 'key',
    amount: amount,
    cardId: 'card',
  );
}

class _FakeRemote implements WalletRemoteDataSource {
  _FakeRemote({required this.checkoutUrl});

  final String checkoutUrl;
  String? currency;
  String? description;
  final List<String> currencies = [];
  final List<String> keys = [];

  @override
  Future<RechargeIntentDto> createRechargeIntent(
    String cardId,
    double amount, {
    required String currency,
    required String idempotencyKey,
    required String description,
  }) async {
    this.currency = currency;
    this.description = description;
    currencies.add(currency);
    keys.add(idempotencyKey);
    return RechargeIntentDto(
      id: 'intent-1',
      preferenceId: 'pref-1',
      checkoutUrl: checkoutUrl,
      status: 'pending',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.countryCode);
  final String countryCode;

  @override
  Future<Result<UserProfile>> getMe() async => Success(
    UserProfile(
      id: 'user',
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      countryCode: countryCode,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CubitRepository implements WalletRepository {
  String? syncedIntentId;
  int configCalls = 0;

  @override
  Future<Result<RechargeIntent>> syncRechargeIntent(String intentId) async {
    syncedIntentId = intentId;
    return Success(
      RechargeIntent(
        id: intentId,
        checkoutUrl: 'https://www.mercadopago.com.co/pay',
        status: 'pending',
      ),
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> mercadoPagoConfig() async {
    configCalls++;
    return const Success({});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RechargeAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final value = {
      'intentId': 'intent-1',
      'preferenceId': 'pref-1',
      'checkoutUrl': 'https://www.mercadopago.cl/checkout',
      'status': 'pending',
    };
    return ResponseBody.fromString(
      jsonEncode({'status': true, 'value': value}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

NetworkClient _client(HttpClientAdapter adapter) {
  const config = AppConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: 'https://example.test',
    refreshTokenPath: '/api/auth/refresh-token',
    connectTimeout: Duration(seconds: 1),
    receiveTimeout: Duration(seconds: 1),
  );
  final session = SessionManager(_MemoryStorage());
  final client = NetworkClient(
    config: config,
    sessionManager: session,
    tokenRefresher: AuthTokenRefresher(config: config, sessionManager: session),
  );
  client.dio.httpClientAdapter = adapter;
  return client;
}

class _MemoryStorage implements SecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async => values.remove(key);
  @override
  Future<void> deleteAll() async => values.clear();
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
