import '../../domain/entities/move_driver.dart';
import '../../domain/entities/move_trip.dart';

enum MoveDriverStatusView { initial, loading, loaded, failure }

class MoveDriverState {
  const MoveDriverState({
    this.status = MoveDriverStatusView.initial,
    this.profile,
    this.availableTrips = const [],
    this.activeTrip,
    this.isOnline = false,
    this.actionInProgress = false,
    this.errorMessage,
    this.successMessage,
  });

  final MoveDriverStatusView status;
  final MoveDriverProfile? profile;
  final List<MoveTrip> availableTrips;
  final MoveTrip? activeTrip;
  final bool isOnline;
  final bool actionInProgress;
  final String? errorMessage;
  final String? successMessage;

  bool get hasProfile => profile != null;

  bool get isApproved => profile?.isApproved ?? false;

  MoveDriverState copyWith({
    MoveDriverStatusView? status,
    MoveDriverProfile? profile,
    List<MoveTrip>? availableTrips,
    MoveTrip? activeTrip,
    bool? isOnline,
    bool? actionInProgress,
    String? errorMessage,
    String? successMessage,
    bool clearProfile = false,
    bool clearActiveTrip = false,
    bool clearMessages = false,
  }) {
    return MoveDriverState(
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
      availableTrips: availableTrips ?? this.availableTrips,
      activeTrip: clearActiveTrip ? null : (activeTrip ?? this.activeTrip),
      isOnline: isOnline ?? this.isOnline,
      actionInProgress: actionInProgress ?? this.actionInProgress,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}
