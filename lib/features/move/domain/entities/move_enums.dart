/// Enums del módulo CIERVO MOVE (movilidad / ride-hailing).
///
/// Se modelan por valor entero (no por nombre) porque el backend envía enteros.
/// Ver docs/CIERVO_APP_FLUTTER_ADAPTATION.md.
library;

enum MoveTripStatus {
  draft(1),
  searching(2),
  offered(3),
  driverAssigned(4),
  driverArriving(7),
  driverArrived(8),
  inProgress(9),
  completed(10),
  cancelledByUser(11),
  cancelledByDriver(12),
  cancelledBySystem(13),
  expired(14),
  pendingParent(16),
  unknown(0);

  const MoveTripStatus(this.value);

  final int value;

  static MoveTripStatus fromValue(Object? raw) {
    final value = _asInt(raw);
    if (value != null) {
      for (final status in MoveTripStatus.values) {
        if (status.value == value) return status;
      }
    }
    return _fromName(raw);
  }

  static MoveTripStatus _fromName(Object? raw) {
    final name = raw?.toString().trim().toLowerCase() ?? '';
    return switch (name) {
      'draft' => MoveTripStatus.draft,
      'searching' => MoveTripStatus.searching,
      'offered' => MoveTripStatus.offered,
      'driverassigned' || 'driver_assigned' => MoveTripStatus.driverAssigned,
      'driverarriving' || 'driver_arriving' => MoveTripStatus.driverArriving,
      'driverarrived' || 'driver_arrived' => MoveTripStatus.driverArrived,
      'inprogress' || 'in_progress' => MoveTripStatus.inProgress,
      'completed' => MoveTripStatus.completed,
      'cancelledbyuser' ||
      'cancelled_by_user' => MoveTripStatus.cancelledByUser,
      'cancelledbydriver' ||
      'cancelled_by_driver' => MoveTripStatus.cancelledByDriver,
      'cancelledbysystem' ||
      'cancelled_by_system' => MoveTripStatus.cancelledBySystem,
      'expired' => MoveTripStatus.expired,
      'pendingparent' || 'pending_parent' => MoveTripStatus.pendingParent,
      _ => MoveTripStatus.unknown,
    };
  }

  /// Viaje Kids esperando aprobación del tutor (no difundido a conductores).
  bool get isPendingParent => this == pendingParent;

  bool get isActive =>
      this == pendingParent ||
      this == searching ||
      this == offered ||
      this == driverAssigned ||
      this == driverArriving ||
      this == driverArrived ||
      this == inProgress;

  bool get isCancelled =>
      this == cancelledByUser ||
      this == cancelledByDriver ||
      this == cancelledBySystem ||
      this == expired;

  bool get isFinished => this == completed || isCancelled;
}

enum MovePaymentStatus {
  none(0),
  pending(1),
  held(2),
  captured(3),
  released(4),
  failed(5),
  refunded(6);

  const MovePaymentStatus(this.value);

  final int value;

  static MovePaymentStatus fromValue(Object? raw) {
    final value = _asInt(raw);
    for (final status in MovePaymentStatus.values) {
      if (status.value == value) return status;
    }
    return MovePaymentStatus.none;
  }

  bool get isHeldOrCaptured => this == held || this == captured;
}

enum MovePaymentMethod {
  wallet(1),
  cash(2),
  card(3),
  pin(4),
  qr(5),
  points(6);

  const MovePaymentMethod(this.value);

  final int value;

  static MovePaymentMethod fromValue(Object? raw) {
    final value = _asInt(raw);
    for (final method in MovePaymentMethod.values) {
      if (method.value == value) return method;
    }
    return MovePaymentMethod.wallet;
  }
}

enum MoveVehicleCategory {
  economy(1),
  standard(2),
  premium(3),
  corporate(4);

  const MoveVehicleCategory(this.value);

  final int value;

  static MoveVehicleCategory fromValue(Object? raw) {
    final value = _asInt(raw);
    for (final category in MoveVehicleCategory.values) {
      if (category.value == value) return category;
    }
    return MoveVehicleCategory.standard;
  }
}

enum MoveDriverStatus {
  none(0),
  pendingReview(1),
  approved(2),
  rejected(3),
  suspended(4),
  blocked(5);

  const MoveDriverStatus(this.value);

  final int value;

  static MoveDriverStatus fromValue(Object? raw) {
    final value = _asInt(raw);
    if (value != null) {
      for (final status in MoveDriverStatus.values) {
        if (status.value == value) return status;
      }
    }
    final name = raw?.toString().trim().toLowerCase() ?? '';
    return switch (name) {
      'pendingreview' ||
      'pending_review' ||
      'pending' => MoveDriverStatus.pendingReview,
      'approved' => MoveDriverStatus.approved,
      'rejected' => MoveDriverStatus.rejected,
      'suspended' => MoveDriverStatus.suspended,
      'blocked' => MoveDriverStatus.blocked,
      _ => MoveDriverStatus.none,
    };
  }

  bool get isApproved => this == approved;
}

int? _asInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw.trim());
  return null;
}
