import 'dart:convert';

import 'package:ciervo_clud/core/config/app_config.dart';
import 'package:ciervo_clud/core/config/app_environment.dart';
import 'package:ciervo_clud/core/storage/secure_storage.dart';
import 'package:ciervo_clud/features/move/data/onboarding/release_terms_configuration_repository.dart';
import 'package:ciervo_clud/features/move/data/onboarding/secure_move_onboarding_draft_store.dart';
import 'package:ciervo_clud/features/move/data/onboarding/sha256.dart';
import 'package:ciervo_clud/features/move/domain/onboarding/move_onboarding_draft.dart';
import 'package:ciervo_clud/features/move/domain/onboarding/move_onboarding_enums.dart';
import 'package:ciervo_clud/features/move/domain/onboarding/move_terms_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SHA-256 coincide con vector conocido', () {
    expect(
      sha256Hex('abc'),
      'ba7816bf8f01cfea414140de5dae2223'
      'b00361a396177a9cb410ff61f20015ad',
    );
  });

  test('store aísla usuarios y persiste solo hash, key y asset ids', () async {
    final storage = _MemoryStorage();
    final store = SecureMoveOnboardingDraftStore(
      storage,
      now: () => DateTime.utc(2026, 7, 18),
    );
    await store.write(
      'user-a',
      const MoveOnboardingDraft(
        countryCode: 'CO',
        currentStage: MoveOnboardingStageType.identity,
        assetIds: {'selfie': 101},
      ),
    );
    final first = await store.saveIntent(
      userId: 'user-a',
      operation: 'identity',
      idempotencyKey: 'intent-a',
      payload: {'documentNumber': 'NO-DEBE-PERSISTIR'},
    );
    final retried = await store.saveIntent(
      userId: 'user-a',
      operation: 'identity',
      idempotencyKey: 'otra-key-ignorada',
      payload: {'documentNumber': 'NO-DEBE-PERSISTIR'},
    );

    expect(retried.idempotencyKey, first.idempotencyKey);
    expect((await store.read('user-a'))!.assetIds['selfie'], 101);
    expect(await store.read('user-b'), isNull);
    final persisted = storage.values.values.single;
    expect(persisted, isNot(contains('NO-DEBE-PERSISTIR')));
    expect(persisted, contains('payloadHash'));
    expect(storage.values.keys.single, isNot(contains('user-a')));
  });

  test('store rechaza reutilizar key con payload diferente', () async {
    final store = SecureMoveOnboardingDraftStore(_MemoryStorage());
    await store.saveIntent(
      userId: 'u',
      operation: 'license',
      idempotencyKey: 'same',
      payload: {'asset': 1},
    );

    expect(
      () => store.saveIntent(
        userId: 'u',
        operation: 'license',
        idempotencyKey: 'same',
        payload: {'asset': 2},
      ),
      throwsStateError,
    );
  });

  test(
    'release terms bloquea configuración incompleta y decodifica Base64',
    () {
      const legalText = 'Términos coordinados';
      final disabled = ReleaseTermsConfigurationRepository(_config());
      expect(
        () => disabled.configurationFor('CO'),
        throwsA(isA<MoveTermsConfigurationException>()),
      );

      final enabled = ReleaseTermsConfigurationRepository(
        _config(
          enabled: true,
          coText: base64Encode(utf8.encode(legalText)),
          coVersion: '2026-01',
          coHash: sha256Hex(legalText),
        ),
      );
      expect(enabled.configurationFor('CO').text, legalText);
      expect(
        () => ReleaseTermsConfigurationRepository(
          _config(
            enabled: true,
            coText: base64Encode(utf8.encode(legalText)),
            coVersion: '2026-01',
            coHash: List.filled(64, 'a').join(),
          ),
        ).configurationFor('CO'),
        throwsA(isA<MoveTermsConfigurationException>()),
      );
    },
  );
}

AppConfig _config({
  bool enabled = false,
  String coText = '',
  String coVersion = '',
  String coHash = '',
}) {
  return AppConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: 'https://example.test',
    refreshTokenPath: '/api/auth/refresh-token',
    connectTimeout: const Duration(seconds: 1),
    receiveTimeout: const Duration(seconds: 1),
    moveOnboardingEnabled: enabled,
    moveTermsCoTextBase64: coText,
    moveTermsCoVersion: coVersion,
    moveTermsCoContentHash: coHash,
  );
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
