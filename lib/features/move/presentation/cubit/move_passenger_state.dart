import '../../domain/entities/move_driver_location.dart';
import '../../domain/entities/move_fare_quote.dart';
import '../../domain/entities/move_offer.dart';
import '../../domain/entities/move_trip.dart';

enum MovePassengerStatus { idle, estimating, requesting, tracking }

class MovePassengerState {
  const MovePassengerState({
    this.status = MovePassengerStatus.idle,
    this.quote,
    this.trip,
    this.offers = const [],
    this.driverLocation,
    this.actionInProgress = false,
    this.errorMessage,
    this.successMessage,
  });

  final MovePassengerStatus status;
  final MoveFareQuote? quote;
  final MoveTrip? trip;
  final List<MoveOffer> offers;
  final MoveDriverLocation? driverLocation;
  final bool actionInProgress;
  final String? errorMessage;
  final String? successMessage;

  bool get isBusy =>
      status == MovePassengerStatus.estimating ||
      status == MovePassengerStatus.requesting ||
      actionInProgress;

  MovePassengerState copyWith({
    MovePassengerStatus? status,
    MoveFareQuote? quote,
    MoveTrip? trip,
    List<MoveOffer>? offers,
    MoveDriverLocation? driverLocation,
    bool? actionInProgress,
    String? errorMessage,
    String? successMessage,
    bool clearQuote = false,
    bool clearTrip = false,
    bool clearMessages = false,
  }) {
    return MovePassengerState(
      status: status ?? this.status,
      quote: clearQuote ? null : (quote ?? this.quote),
      trip: clearTrip ? null : (trip ?? this.trip),
      offers: offers ?? this.offers,
      driverLocation: driverLocation ?? this.driverLocation,
      actionInProgress: actionInProgress ?? this.actionInProgress,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}
