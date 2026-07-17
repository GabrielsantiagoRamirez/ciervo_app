import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../domain/entities/move_enums.dart';
import '../../domain/entities/move_fare_quote.dart';
import '../../domain/repositories/move_repository.dart';
import 'move_passenger_state.dart';

class MovePassengerCubit extends Cubit<MovePassengerState> {
  MovePassengerCubit(this._repository) : super(const MovePassengerState());

  final MoveRepository _repository;

  Timer? _pollTimer;
  bool _polling = false;

  static const _pollInterval = Duration(seconds: 3);

  Future<void> estimateFare(MoveFareRequest request) async {
    emit(
      state.copyWith(
        status: MovePassengerStatus.estimating,
        clearMessages: true,
      ),
    );
    final result = await _repository.calculateFare(request);
    result.when(
      success: (quote) => emit(
        state.copyWith(status: MovePassengerStatus.idle, quote: quote),
      ),
      failure: (error) => emit(
        state.copyWith(
          status: MovePassengerStatus.idle,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  /// Solicita el viaje. Devuelve el id del viaje creado o null si falló.
  Future<String?> requestTrip({
    required MoveFareRequest fare,
    required double originLat,
    required double originLng,
    required String originAddress,
    required double destLat,
    required double destLng,
    required String destAddress,
    required MovePaymentMethod paymentMethod,
    int offeredFare = 0,
    String? childProfileId,
  }) async {
    emit(
      state.copyWith(
        status: MovePassengerStatus.requesting,
        clearMessages: true,
      ),
    );
    final result = await _repository.requestTrip(
      fare: fare,
      originLat: originLat,
      originLng: originLng,
      originAddress: originAddress,
      destLat: destLat,
      destLng: destLng,
      destAddress: destAddress,
      paymentMethod: paymentMethod,
      offeredFare: offeredFare,
      childProfileId: childProfileId,
    );
    return result.when(
      success: (trip) {
        // El tracking lo inicia la pantalla de seguimiento (dueña del polling).
        emit(state.copyWith(status: MovePassengerStatus.idle, clearTrip: true));
        return trip.id;
      },
      failure: (error) {
        emit(
          state.copyWith(
            status: MovePassengerStatus.idle,
            errorMessage: UserErrorMessage.from(error),
          ),
        );
        return null;
      },
    );
  }

  void startTracking(String tripId) {
    _pollTimer?.cancel();
    unawaited(_refresh(tripId));
    _pollTimer = Timer.periodic(_pollInterval, (_) => _refresh(tripId));
  }

  void stopTracking() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _refresh(String tripId) async {
    if (_polling) return;
    _polling = true;
    try {
      final tripResult = await _repository.getTrip(tripId);
      tripResult.when(
        success: (trip) {
          emit(state.copyWith(trip: trip));
          if (trip.status.isFinished) {
            stopTracking();
          }
        },
        failure: (_) {},
      );

      final trip = state.trip;
      if (trip == null || trip.status.isFinished) {
        return;
      }

      // Ofertas solo mientras se negocia.
      if (trip.status == MoveTripStatus.searching ||
          trip.status == MoveTripStatus.offered) {
        final offersResult = await _repository.getOffers(tripId);
        offersResult.when(
          success: (offers) => emit(state.copyWith(offers: offers)),
          failure: (_) {},
        );
      }

      // Ubicación del conductor una vez asignado.
      if (trip.hasDriver) {
        final locationResult = await _repository.getTripLocation(tripId);
        locationResult.when(
          success: (location) {
            if (location != null) {
              emit(state.copyWith(driverLocation: location));
            }
          },
          failure: (_) {},
        );
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> acceptOffer(String offerId) async {
    final tripId = state.trip?.id;
    if (tripId == null) return;
    emit(state.copyWith(actionInProgress: true, clearMessages: true));
    final result = await _repository.acceptOffer(
      tripId: tripId,
      offerId: offerId,
    );
    result.when(
      success: (trip) {
        // Verifica que el hold del wallet no haya fallado.
        if (trip.paymentMethod == MovePaymentMethod.wallet &&
            trip.paymentStatus == MovePaymentStatus.failed) {
          emit(
            state.copyWith(
              actionInProgress: false,
              trip: trip,
              errorMessage:
                  'No pudimos retener el saldo en tu wallet. Recárgala e intenta con otra oferta.',
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            actionInProgress: false,
            trip: trip,
            successMessage: 'Oferta aceptada. Tu conductor va en camino.',
          ),
        );
        startTracking(trip.id);
      },
      failure: (error) => emit(
        state.copyWith(
          actionInProgress: false,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> counterOffer(String offerId, int amount) async {
    final tripId = state.trip?.id;
    if (tripId == null) return;
    emit(state.copyWith(actionInProgress: true, clearMessages: true));
    final result = await _repository.counterOffer(
      tripId: tripId,
      offerId: offerId,
      amount: amount,
    );
    result.when(
      success: (_) => emit(
        state.copyWith(
          actionInProgress: false,
          successMessage: 'Contraoferta enviada al conductor.',
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

  Future<void> cancelTrip(String reason) async {
    final tripId = state.trip?.id;
    if (tripId == null) return;
    emit(state.copyWith(actionInProgress: true, clearMessages: true));
    final result = await _repository.cancelTrip(tripId: tripId, reason: reason);
    result.when(
      success: (_) {
        stopTracking();
        emit(
          state.copyWith(
            actionInProgress: false,
            successMessage: 'Viaje cancelado.',
          ),
        );
        unawaited(_refresh(tripId));
      },
      failure: (error) => emit(
        state.copyWith(
          actionInProgress: false,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> rateTrip(int rating, String? comment) async {
    final tripId = state.trip?.id;
    if (tripId == null) return;
    emit(state.copyWith(actionInProgress: true, clearMessages: true));
    final result = await _repository.rateTrip(
      tripId: tripId,
      rating: rating,
      comment: comment,
    );
    result.when(
      success: (_) => emit(
        state.copyWith(
          actionInProgress: false,
          successMessage: '¡Gracias por calificar tu viaje!',
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

  /// Envía una alerta SOS del viaje activo (notifica al tutor y al conductor).
  Future<bool> sendSos({double? latitude, double? longitude, String? note}) async {
    final tripId = state.trip?.id;
    if (tripId == null) return false;
    emit(state.copyWith(actionInProgress: true, clearMessages: true));
    final result = await _repository.sos(
      tripId: tripId,
      latitude: latitude,
      longitude: longitude,
      note: note,
    );
    return result.when(
      success: (_) {
        emit(
          state.copyWith(
            actionInProgress: false,
            successMessage: 'Alerta SOS enviada. Notificamos al tutor y al conductor.',
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

  void clearQuote() => emit(state.copyWith(clearQuote: true));

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
