import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/move_enums.dart';
import '../../domain/entities/move_trip.dart';
import '../../domain/repositories/move_repository.dart';
import 'move_driver_state.dart';

class MoveDriverCubit extends Cubit<MoveDriverState> {
  MoveDriverCubit(this._repository, this._locationService)
    : super(const MoveDriverState());

  final MoveRepository _repository;
  final LocationService _locationService;

  Timer? _locationTimer;
  Timer? _availableTimer;
  bool _busy = false;

  static const _locationInterval = Duration(seconds: 6);
  static const _availableInterval = Duration(seconds: 5);

  Future<void> load() async {
    emit(
      state.copyWith(status: MoveDriverStatusView.loading, clearMessages: true),
    );
    final result = await _repository.getDriverProfile();
    await result.when(
      success: (profile) async {
        emit(
          state.copyWith(
            status: MoveDriverStatusView.loaded,
            profile: profile,
            isOnline: profile?.isOnline ?? false,
            clearProfile: profile == null,
          ),
        );
        if (profile?.isApproved ?? false) {
          await _loadActiveTrip();
          if (profile!.isOnline) {
            _startPolling();
          }
        }
      },
      failure: (error) async => emit(
        state.copyWith(
          status: MoveDriverStatusView.failure,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<bool> apply({
    required String fullName,
    required String phone,
    required String countryCode,
    required String city,
  }) async {
    emit(state.copyWith(actionInProgress: true, clearMessages: true));
    final result = await _repository.applyAsDriver(
      fullName: fullName,
      phone: phone,
      countryCode: countryCode,
      city: city,
    );
    return result.when(
      success: (profile) {
        emit(
          state.copyWith(
            actionInProgress: false,
            profile: profile,
            status: MoveDriverStatusView.loaded,
            successMessage: 'Solicitud enviada. Ahora registra tu vehículo.',
          ),
        );
        return true;
      },
      failure: (error) {
        emit(
          state.copyWith(
            actionInProgress: false,
            errorMessage: UserErrorMessage.from(error),
          ),
        );
        return false;
      },
    );
  }

  Future<bool> addVehicle(MoveVehicleInput input) async {
    emit(state.copyWith(actionInProgress: true, clearMessages: true));
    final result = await _repository.addVehicle(input);
    return result.when(
      success: (_) {
        emit(
          state.copyWith(
            actionInProgress: false,
            successMessage: 'Vehículo registrado correctamente.',
          ),
        );
        unawaited(load());
        return true;
      },
      failure: (error) {
        emit(
          state.copyWith(
            actionInProgress: false,
            errorMessage: UserErrorMessage.from(error),
          ),
        );
        return false;
      },
    );
  }

  Future<bool> addDocument({
    required String documentType,
    required String fileUrl,
    String? documentNumber,
    DateTime? expiresAt,
  }) async {
    emit(state.copyWith(actionInProgress: true, clearMessages: true));
    final result = await _repository.addDocument(
      documentType: documentType,
      fileUrl: fileUrl,
      documentNumber: documentNumber,
      expiresAt: expiresAt,
    );
    return result.when(
      success: (_) {
        emit(
          state.copyWith(
            actionInProgress: false,
            successMessage: 'Documento enviado para revisión.',
          ),
        );
        unawaited(load());
        return true;
      },
      failure: (error) {
        emit(
          state.copyWith(
            actionInProgress: false,
            errorMessage: UserErrorMessage.from(error),
          ),
        );
        return false;
      },
    );
  }

  Future<void> toggleOnline(bool goOnline) async {
    final profile = state.profile;
    if (profile == null) return;
    if (goOnline && !profile.canGoOnline) {
      emit(
        state.copyWith(
          errorMessage:
              'Necesitas estar aprobado y tener un vehículo activo para ponerte en línea.',
        ),
      );
      return;
    }
    emit(state.copyWith(actionInProgress: true, clearMessages: true));
    AppLocation? location;
    if (goOnline) {
      location = await _safeLocation();
      if (location == null) {
        emit(
          state.copyWith(
            actionInProgress: false,
            errorMessage:
                'No pudimos obtener tu ubicación. Intenta nuevamente antes '
                'de conectarte.',
          ),
        );
        return;
      }
    }
    final result = await _repository.setOnline(
      isOnline: goOnline,
      latitude: location?.latitude,
      longitude: location?.longitude,
    );
    result.when(
      success: (_) {
        emit(
          state.copyWith(
            actionInProgress: false,
            isOnline: goOnline,
            successMessage: goOnline
                ? 'Estás en línea. Recibirás viajes cercanos.'
                : 'Estás fuera de línea.',
          ),
        );
        if (goOnline) {
          _startPolling();
        } else {
          _stopPolling();
        }
      },
      failure: (error) => emit(
        state.copyWith(
          actionInProgress: false,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> refreshAvailable() async {
    if (!state.isOnline) return;
    final result = await _repository.availableTrips();
    result.when(
      success: (trips) => emit(state.copyWith(availableTrips: trips)),
      failure: (_) {},
    );
  }

  Future<bool> submitOffer({
    required String tripId,
    required int amount,
    required String vehicleId,
    int? etaMinutes,
    String? message,
  }) async {
    emit(state.copyWith(actionInProgress: true, clearMessages: true));
    final result = await _repository.submitOffer(
      tripId: tripId,
      amount: amount,
      vehicleId: vehicleId,
      etaMinutes: etaMinutes,
      message: message,
    );
    return result.when(
      success: (_) {
        emit(
          state.copyWith(
            actionInProgress: false,
            successMessage: 'Oferta enviada. Espera la respuesta del pasajero.',
          ),
        );
        unawaited(_loadActiveTrip());
        return true;
      },
      failure: (error) {
        emit(
          state.copyWith(
            actionInProgress: false,
            errorMessage: UserErrorMessage.from(error),
          ),
        );
        return false;
      },
    );
  }

  Future<void> arriving() => _transition(_repository.driverArriving);

  Future<void> arrived() => _transition(_repository.driverArrived);

  Future<void> startTrip() => _transition(_repository.driverStart);

  Future<void> finishTrip() => _transition(
    _repository.driverFinish,
    successMessage: 'Viaje finalizado. El pago fue liquidado.',
  );

  Future<void> _transition(
    Future<Result<MoveTrip>> Function(String tripId) action, {
    String? successMessage,
  }) async {
    final tripId = state.activeTrip?.id;
    if (tripId == null) return;
    emit(state.copyWith(actionInProgress: true, clearMessages: true));
    final result = await action(tripId);
    result.when(
      success: (trip) => emit(
        state.copyWith(
          actionInProgress: false,
          activeTrip: trip,
          successMessage: successMessage,
          clearActiveTrip: trip.status.isFinished,
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          actionInProgress: false,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> cancelActiveTrip(String reason) async {
    final tripId = state.activeTrip?.id;
    if (tripId == null) return;
    emit(state.copyWith(actionInProgress: true, clearMessages: true));
    final result = await _repository.driverCancel(
      tripId: tripId,
      reason: reason,
    );
    result.when(
      success: (_) => emit(
        state.copyWith(
          actionInProgress: false,
          clearActiveTrip: true,
          successMessage: 'Viaje cancelado.',
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          actionInProgress: false,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> rateActiveTrip(int rating, String? comment) async {
    final tripId = state.activeTrip?.id;
    if (tripId == null) return;
    emit(state.copyWith(actionInProgress: true, clearMessages: true));
    final result = await _repository.driverRate(
      tripId: tripId,
      rating: rating,
      comment: comment,
    );
    result.when(
      success: (_) => emit(
        state.copyWith(
          actionInProgress: false,
          clearActiveTrip: true,
          successMessage: 'Calificaste al pasajero.',
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          actionInProgress: false,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> _loadActiveTrip() async {
    final result = await _repository.driverTrips(pageSize: 10);
    result.when(
      success: (trips) {
        final active = trips.where((t) => t.status.isActive).toList();
        emit(
          state.copyWith(
            activeTrip: active.isNotEmpty ? active.first : null,
            clearActiveTrip: active.isEmpty,
          ),
        );
      },
      failure: (_) {},
    );
  }

  void _startPolling() {
    _stopPolling();
    unawaited(refreshAvailable());
    unawaited(_pushLocation());
    _availableTimer = Timer.periodic(
      _availableInterval,
      (_) => refreshAvailable(),
    );
    _locationTimer = Timer.periodic(_locationInterval, (_) => _pushLocation());
  }

  void _stopPolling() {
    _availableTimer?.cancel();
    _locationTimer?.cancel();
    _availableTimer = null;
    _locationTimer = null;
  }

  Future<void> _pushLocation() async {
    if (_busy || !state.isOnline) return;
    _busy = true;
    try {
      final location = await _safeLocation();
      if (location == null) return;
      await _repository.sendDriverLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        tripId: state.activeTrip?.id,
      );
    } finally {
      _busy = false;
    }
  }

  Future<AppLocation?> _safeLocation() async {
    try {
      return await _locationService.currentLocation();
    } catch (_) {
      return _locationService.lastKnownLocation();
    }
  }

  MoveVehicleCategory? get defaultVehicleCategory =>
      state.profile?.vehicles.where((v) => v.isActive).firstOrNull?.category;

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
