import 'package:ciervo_clud/core/errors/app_exception.dart';
import 'package:ciervo_clud/core/result/result.dart';
import 'package:ciervo_clud/core/storage/secure_storage.dart';
import 'package:ciervo_clud/features/move/data/media/move_media_models.dart';
import 'package:ciervo_clud/features/move/data/onboarding/secure_move_onboarding_draft_store.dart';
import 'package:ciervo_clud/features/move/domain/onboarding/move_onboarding_draft.dart';
import 'package:ciervo_clud/features/move/domain/onboarding/move_onboarding_enums.dart';
import 'package:ciervo_clud/features/move/domain/onboarding/move_onboarding_repository.dart';
import 'package:ciervo_clud/features/move/domain/onboarding/move_onboarding_requests.dart';
import 'package:ciervo_clud/features/move/domain/onboarding/move_onboarding_status.dart';
import 'package:ciervo_clud/features/move/domain/onboarding/move_terms_configuration.dart';
import 'package:ciervo_clud/features/move/presentation/onboarding/move_onboarding_cubit.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reanuda la etapa guardada y refresca estado al entrar', () async {
    final store = SecureMoveOnboardingDraftStore(_MemoryStorage());
    await store.write(
      'user-1',
      const MoveOnboardingDraft(
        countryCode: 'CL',
        currentStage: MoveOnboardingStageType.license,
      ),
    );
    final cubit = _cubit(store: store);

    await cubit.load();

    expect(cubit.state.currentStage, MoveOnboardingStageType.license);
    expect(cubit.state.draft.countryCode, 'CL');
    expect(cubit.state.status?.driverId, 7);
    await cubit.close();
  });

  test('conserva la misma key tras fallo transitorio', () async {
    final store = SecureMoveOnboardingDraftStore(_MemoryStorage());
    final repository = _Repository()
      ..operationResults.addAll([
        const Failure(AppException(message: 'offline', statusCode: 503)),
        Success(_status()),
      ]);
    final cubit = _cubit(store: store, repository: repository);
    await cubit.load();
    final request = _operations();

    expect(await cubit.saveOperations(request), isFalse);
    expect(await cubit.saveOperations(request), isTrue);

    expect(repository.keys, hasLength(2));
    expect(repository.keys[1], repository.keys[0]);
    expect((await store.read('user-1'))!.intents, isEmpty);
    await cubit.close();
  });

  test('completa intent ante respuesta definitiva', () async {
    final store = SecureMoveOnboardingDraftStore(_MemoryStorage());
    final repository = _Repository()
      ..operationResults.add(
        const Failure(AppException(message: 'invalid', statusCode: 422)),
      );
    final cubit = _cubit(store: store, repository: repository);
    await cubit.load();

    expect(await cubit.saveOperations(_operations()), isFalse);

    expect((await store.read('user-1'))!.intents, isEmpty);
    await cubit.close();
  });

  for (final statusCode in const [400, 401, 403, 404, 409, 422, 429]) {
    test('cierra intención ante HTTP definitivo $statusCode', () async {
      final store = SecureMoveOnboardingDraftStore(_MemoryStorage());
      final repository = _Repository()
        ..operationResults.add(
          Failure(AppException(message: 'definitivo', statusCode: statusCode)),
        );
      final cubit = _cubit(store: store, repository: repository);
      await cubit.load();

      expect(await cubit.saveOperations(_operations()), isFalse);
      expect((await store.read('user-1'))!.intents, isEmpty);
      await cubit.close();
    });
  }

  test('conserva intención ante timeout sin respuesta HTTP', () async {
    final store = SecureMoveOnboardingDraftStore(_MemoryStorage());
    final repository = _Repository()
      ..operationResults.add(const Failure(AppException(message: 'timeout')));
    final cubit = _cubit(store: store, repository: repository);
    await cubit.load();

    expect(await cubit.saveOperations(_operations()), isFalse);
    expect((await store.read('user-1'))!.intents, contains('operations'));
    await cubit.close();
  });
}

MoveOnboardingCubit _cubit({
  required MoveOnboardingDraftStore store,
  _Repository? repository,
}) {
  return MoveOnboardingCubit(
    repository: repository ?? _Repository(),
    draftStore: store,
    termsRepository: const _Terms(),
    uploadImage:
        ({
          required String path,
          required String originalFileName,
          void Function(int, int)? onProgress,
          CancelToken? cancelToken,
        }) async => const Success(MoveMediaAsset(id: 1)),
    userId: 'user-1',
  );
}

MoveOperationsOnboardingRequest _operations() {
  return const MoveOperationsOnboardingRequest(
    emergencyName: 'Contacto Seguro',
    emergencyPhone: '+573001234567',
    emergencyRelationship: 'Familiar',
    languages: ['Español'],
    accessible: false,
    pets: true,
    airConditioning: true,
    luggage: true,
    isAvailableNow: true,
    services: [MoveServiceType.economy],
  );
}

MoveDriverOnboardingStatus _status({bool canSubmit = false}) {
  return MoveDriverOnboardingStatus(
    driverId: 7,
    status: MoveDriverStatus.draft,
    percentage: 25,
    canSubmit: canSubmit,
    canGoOnline: false,
    vehicleDocuments: const [],
    stages: const [],
    missing: const [],
    reasons: const [],
  );
}

class _Repository implements MoveOnboardingRepository {
  final List<Result<MoveDriverOnboardingStatus>> operationResults = [];
  final List<String> keys = [];

  Result<MoveDriverOnboardingStatus> _next(String key) {
    keys.add(key);
    return operationResults.isEmpty
        ? Success(_status())
        : operationResults.removeAt(0);
  }

  @override
  Future<Result<MoveDriverOnboardingStatus>> getStatus() async =>
      Success(_status());

  @override
  Future<Result<MoveDriverOnboardingStatus>> saveIdentity(
    MoveIdentityOnboardingRequest request, {
    required String idempotencyKey,
  }) async => _next(idempotencyKey);

  @override
  Future<Result<MoveDriverOnboardingStatus>> saveLicense(
    MoveLicenseOnboardingRequest request, {
    required String idempotencyKey,
  }) async => _next(idempotencyKey);

  @override
  Future<Result<MoveDriverOnboardingStatus>> saveOperations(
    MoveOperationsOnboardingRequest request, {
    required String idempotencyKey,
  }) async => _next(idempotencyKey);

  @override
  Future<Result<MoveDriverOnboardingStatus>> saveVehicle(
    MoveVehicleOnboardingRequest request, {
    required String idempotencyKey,
  }) async => _next(idempotencyKey);

  @override
  Future<Result<MoveDriverOnboardingStatus>> submit({
    required String idempotencyKey,
  }) async => _next(idempotencyKey);
}

class _Terms implements TermsConfigurationRepository {
  const _Terms();

  @override
  bool get isOnboardingEnabled => true;

  @override
  MoveTermsConfiguration configurationFor(String countryCode) {
    return MoveTermsConfiguration(
      countryCode: countryCode,
      text: 'Términos',
      version: 'v1',
      contentHash: List.filled(64, 'a').join(),
    );
  }
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
