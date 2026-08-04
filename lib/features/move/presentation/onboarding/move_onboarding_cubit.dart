import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/user_error_message.dart';
import '../../../../core/result/result.dart';
import '../../../../core/utils/idempotency_key.dart';
import '../../data/media/move_media_models.dart';
import '../../domain/onboarding/move_onboarding_draft.dart';
import '../../domain/onboarding/move_onboarding_enums.dart';
import '../../domain/onboarding/move_onboarding_repository.dart';
import '../../domain/onboarding/move_onboarding_requests.dart';
import '../../domain/onboarding/move_onboarding_status.dart';
import '../../domain/onboarding/move_terms_configuration.dart';

enum MoveOnboardingLoadState { initial, loading, ready, failure }

class MoveOnboardingState {
  const MoveOnboardingState({
    this.loadState = MoveOnboardingLoadState.initial,
    this.status,
    this.draft = const MoveOnboardingDraft(),
    this.terms,
    this.currentStage = MoveOnboardingStageType.identity,
    this.busy = false,
    this.uploadingAsset,
    this.uploadProgress = 0,
    this.errorMessage,
    this.successMessage,
    this.blockedMessage,
  });

  final MoveOnboardingLoadState loadState;
  final MoveDriverOnboardingStatus? status;
  final MoveOnboardingDraft draft;
  final MoveTermsConfiguration? terms;
  final MoveOnboardingStageType currentStage;
  final bool busy;
  final String? uploadingAsset;
  final double uploadProgress;
  final String? errorMessage;
  final String? successMessage;
  final String? blockedMessage;

  bool get isBlocked => blockedMessage != null;
  bool get canSubmit => status?.canSubmit == true && !busy && !isBlocked;
  int? asset(String key) => draft.assetIds[key];

  MoveOnboardingState copyWith({
    MoveOnboardingLoadState? loadState,
    MoveDriverOnboardingStatus? status,
    MoveOnboardingDraft? draft,
    MoveTermsConfiguration? terms,
    MoveOnboardingStageType? currentStage,
    bool? busy,
    String? uploadingAsset,
    double? uploadProgress,
    String? errorMessage,
    String? successMessage,
    String? blockedMessage,
    bool clearMessages = false,
    bool clearUploading = false,
    bool clearBlocked = false,
  }) {
    return MoveOnboardingState(
      loadState: loadState ?? this.loadState,
      status: status ?? this.status,
      draft: draft ?? this.draft,
      terms: terms ?? this.terms,
      currentStage: currentStage ?? this.currentStage,
      busy: busy ?? this.busy,
      uploadingAsset: clearUploading
          ? null
          : (uploadingAsset ?? this.uploadingAsset),
      uploadProgress: clearUploading
          ? 0
          : (uploadProgress ?? this.uploadProgress),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
      blockedMessage: clearBlocked
          ? null
          : (blockedMessage ?? this.blockedMessage),
    );
  }
}

class MoveOnboardingCubit extends Cubit<MoveOnboardingState> {
  MoveOnboardingCubit({
    required MoveOnboardingRepository repository,
    required MoveOnboardingDraftStore draftStore,
    required TermsConfigurationRepository termsRepository,
    required MoveImageUpload uploadImage,
    required String userId,
  }) : _repository = repository,
       _draftStore = draftStore,
       _termsRepository = termsRepository,
       _uploadImage = uploadImage,
       _userId = userId.trim(),
       super(const MoveOnboardingState());

  final MoveOnboardingRepository _repository;
  final MoveOnboardingDraftStore _draftStore;
  final TermsConfigurationRepository _termsRepository;
  final MoveImageUpload _uploadImage;
  final String _userId;
  CancelToken? _uploadCancelToken;

  Future<void> load({MoveOnboardingStageType? requestedStage}) async {
    if (_userId.isEmpty) {
      emit(
        state.copyWith(
          loadState: MoveOnboardingLoadState.failure,
          blockedMessage: 'No pudimos validar la sesión de cliente.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        loadState: MoveOnboardingLoadState.loading,
        clearMessages: true,
      ),
    );
    final draft =
        await _draftStore.read(_userId) ?? const MoveOnboardingDraft();
    final stage =
        requestedStage ??
        (draft.currentStage == MoveOnboardingStageType.unknown
            ? MoveOnboardingStageType.identity
            : draft.currentStage);
    emit(state.copyWith(draft: draft, currentStage: stage));
    _loadTerms(draft.countryCode ?? 'CO');
    await refreshStatus(showLoading: false);
  }

  Future<void> refreshStatus({bool showLoading = true}) async {
    if (showLoading) {
      emit(
        state.copyWith(
          loadState: MoveOnboardingLoadState.loading,
          clearMessages: true,
        ),
      );
    }
    final result = await _repository.getStatus();
    result.when(
      success: (status) => emit(
        state.copyWith(
          loadState: MoveOnboardingLoadState.ready,
          status: status,
          clearMessages: true,
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          loadState: MoveOnboardingLoadState.failure,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> selectCountry(String countryCode) async {
    final code = countryCode.trim().toUpperCase();
    final draft = state.draft.copyWith(countryCode: code);
    await _draftStore.write(_userId, draft);
    emit(state.copyWith(draft: draft, clearMessages: true));
    _loadTerms(code);
  }

  void _loadTerms(String countryCode) {
    try {
      final terms = _termsRepository.configurationFor(countryCode);
      emit(
        state.copyWith(terms: terms, clearBlocked: true, clearMessages: true),
      );
    } on MoveTermsConfigurationException catch (error) {
      // No bloqueamos toda la UI: el conductor puede cargar identidad/vehículo.
      // Solo avisa; el envío de identidad exige términos válidos.
      emit(
        state.copyWith(
          clearBlocked: true,
          errorMessage:
              '${error.message} Podés completar el formulario; '
              'para enviar se necesita el release con términos habilitados.',
        ),
      );
    }
  }

  Future<bool> uploadImage({
    required String assetKey,
    required String path,
    required String fileName,
  }) async {
    emit(
      state.copyWith(
        busy: true,
        uploadingAsset: assetKey,
        uploadProgress: 0,
        clearMessages: true,
      ),
    );
    final cancelToken = CancelToken();
    _uploadCancelToken = cancelToken;
    final result = await _uploadImage(
      path: path,
      originalFileName: fileName,
      cancelToken: cancelToken,
      onProgress: (sent, total) {
        if (isClosed || total <= 0) return;
        emit(
          state.copyWith(
            uploadProgress: (sent / total).clamp(0.0, 1.0).toDouble(),
          ),
        );
      },
    );
    _uploadCancelToken = null;
    return result.when<Future<bool>>(
      success: (asset) async {
        final assets = Map<String, int>.from(state.draft.assetIds)
          ..[assetKey] = asset.id;
        final draft = state.draft.copyWith(assetIds: Map.unmodifiable(assets));
        await _draftStore.write(_userId, draft);
        emit(
          state.copyWith(
            draft: draft,
            busy: false,
            successMessage: 'Imagen cargada de forma segura.',
            clearUploading: true,
          ),
        );
        return true;
      },
      failure: (error) async {
        emit(
          state.copyWith(
            busy: false,
            errorMessage: UserErrorMessage.from(error),
            clearUploading: true,
          ),
        );
        return false;
      },
    );
  }

  void cancelUpload() {
    _uploadCancelToken?.cancel('Carga cancelada por el usuario.');
  }

  Future<bool> saveIdentity(MoveIdentityOnboardingRequest request) {
    final errors = request.validate();
    if (errors.isNotEmpty) return _validationFailure(errors);
    return _runStatusOperation(
      operation: 'identity',
      payload: request.toJson(),
      action: (key) => _repository.saveIdentity(request, idempotencyKey: key),
      nextStage: MoveOnboardingStageType.license,
      successMessage: 'Identidad guardada.',
    );
  }

  Future<bool> saveLicense(
    MoveLicenseOnboardingRequest request, {
    required String countryCode,
  }) {
    final errors = request.validate(countryCode: countryCode);
    if (errors.isNotEmpty) return _validationFailure(errors);
    return _runStatusOperation(
      operation: 'license',
      payload: request.toJson(),
      action: (key) => _repository.saveLicense(request, idempotencyKey: key),
      nextStage: MoveOnboardingStageType.vehicleAndOperations,
      successMessage: 'Licencia guardada.',
    );
  }

  Future<bool> saveVehicle(
    MoveVehicleOnboardingRequest request, {
    required String countryCode,
    required Iterable<MoveServiceType> services,
  }) {
    final errors = request.validate(
      countryCode: countryCode,
      services: services,
    );
    if (errors.isNotEmpty) return _validationFailure(errors);
    return _runStatusOperation(
      operation: 'vehicle',
      payload: request.toJson(),
      action: (key) => _repository.saveVehicle(request, idempotencyKey: key),
      nextStage: MoveOnboardingStageType.vehicleAndOperations,
      successMessage: 'Vehículo y documentos guardados.',
    );
  }

  Future<bool> saveOperations(MoveOperationsOnboardingRequest request) {
    final errors = request.validate();
    if (errors.isNotEmpty) return _validationFailure(errors);
    return _runStatusOperation(
      operation: 'operations',
      payload: request.toJson(),
      action: (key) => _repository.saveOperations(request, idempotencyKey: key),
      nextStage: MoveOnboardingStageType.vehicleAndOperations,
      successMessage: 'Preferencias operativas guardadas.',
    );
  }

  Future<bool> submit() async {
    if (!state.canSubmit) {
      emit(
        state.copyWith(
          errorMessage:
              'Aún faltan requisitos. Actualiza el estado antes de enviar.',
        ),
      );
      return false;
    }
    return _runStatusOperation(
      operation: 'submit',
      payload: const <String, dynamic>{'intent': 'submit'},
      action: (key) => _repository.submit(idempotencyKey: key),
      nextStage: MoveOnboardingStageType.vehicleAndOperations,
      successMessage: 'Solicitud enviada a revisión.',
    );
  }

  Future<bool> _runStatusOperation({
    required String operation,
    required Map<String, dynamic> payload,
    required Future<Result<MoveDriverOnboardingStatus>> Function(String key)
    action,
    required MoveOnboardingStageType nextStage,
    required String successMessage,
  }) async {
    if (state.isBlocked) return false;
    emit(state.copyWith(busy: true, clearMessages: true));
    final intent = await _draftStore.saveIntent(
      userId: _userId,
      operation: operation,
      idempotencyKey: IdempotencyKey.generate('move-$operation'),
      payload: payload,
    );
    final result = await action(intent.idempotencyKey);
    return result.when<Future<bool>>(
      success: (status) async {
        await _draftStore.completeIntent(_userId, operation);
        final draft = state.draft.copyWith(currentStage: nextStage);
        await _draftStore.write(_userId, draft);
        emit(
          state.copyWith(
            status: status,
            draft: draft,
            currentStage: nextStage,
            busy: false,
            successMessage: successMessage,
          ),
        );
        return true;
      },
      failure: (error) async {
        if (_isDefinitive(error)) {
          await _draftStore.completeIntent(_userId, operation);
        }
        emit(
          state.copyWith(
            busy: false,
            errorMessage: UserErrorMessage.from(error),
          ),
        );
        return false;
      },
    );
  }

  Future<bool> _validationFailure(MoveValidationErrors errors) async {
    final first = errors.values.expand((items) => items).first;
    emit(state.copyWith(errorMessage: first));
    return false;
  }

  bool _isDefinitive(Object error) {
    if (error is! AppException) return false;
    final status = error.statusCode;
    if (status == null || status == 408 || status >= 500) {
      return false;
    }
    return true;
  }

  @override
  Future<void> close() {
    _uploadCancelToken?.cancel('Onboarding cerrado.');
    return super.close();
  }
}

typedef MoveImageUpload =
    Future<Result<MoveMediaAsset>> Function({
      required String path,
      required String originalFileName,
      void Function(int sentBytes, int totalBytes)? onProgress,
      CancelToken? cancelToken,
    });
