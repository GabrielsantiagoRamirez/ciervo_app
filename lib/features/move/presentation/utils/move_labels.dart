import 'package:flutter/material.dart';

import '../../domain/entities/move_enums.dart';

/// Etiquetas en español y metadatos visuales para los enums de MOVE.
abstract final class MoveLabels {
  static String tripStatus(MoveTripStatus status) => switch (status) {
    MoveTripStatus.draft => 'Borrador',
    MoveTripStatus.searching => 'Buscando conductor',
    MoveTripStatus.offered => 'Ofertas recibidas',
    MoveTripStatus.driverAssigned => 'Conductor asignado',
    MoveTripStatus.driverArriving => 'Conductor en camino',
    MoveTripStatus.driverArrived => 'Conductor llegó',
    MoveTripStatus.inProgress => 'Viaje en curso',
    MoveTripStatus.completed => 'Completado',
    MoveTripStatus.cancelledByUser => 'Cancelado por ti',
    MoveTripStatus.cancelledByDriver => 'Cancelado por el conductor',
    MoveTripStatus.cancelledBySystem => 'Cancelado por el sistema',
    MoveTripStatus.expired => 'Expirado',
    MoveTripStatus.pendingParent => 'Esperando aprobación del tutor',
    MoveTripStatus.unknown => 'Estado desconocido',
  };

  static Color tripStatusColor(MoveTripStatus status) {
    if (status.isCancelled) return Colors.redAccent;
    if (status == MoveTripStatus.completed) return Colors.green;
    if (status == MoveTripStatus.inProgress) return Colors.lightBlueAccent;
    return Colors.amber;
  }

  static String paymentStatus(MovePaymentStatus status) => switch (status) {
    MovePaymentStatus.none => 'Sin pago',
    MovePaymentStatus.pending => 'Pago pendiente',
    MovePaymentStatus.held => 'Saldo retenido',
    MovePaymentStatus.captured => 'Pago cobrado',
    MovePaymentStatus.released => 'Retención liberada',
    MovePaymentStatus.failed => 'Pago fallido',
    MovePaymentStatus.refunded => 'Reembolsado',
  };

  static String paymentMethod(MovePaymentMethod method) => switch (method) {
    MovePaymentMethod.wallet => 'Wallet Ciervo',
    MovePaymentMethod.cash => 'Efectivo',
    MovePaymentMethod.card => 'Tarjeta',
    MovePaymentMethod.pin => 'PIN',
    MovePaymentMethod.qr => 'QR',
    MovePaymentMethod.points => 'Puntos',
  };

  static String vehicleCategory(MoveVehicleCategory category) =>
      switch (category) {
        MoveVehicleCategory.economy => 'Económico',
        MoveVehicleCategory.standard => 'Estándar',
        MoveVehicleCategory.premium => 'Premium',
        MoveVehicleCategory.corporate => 'Corporativo',
      };

  static IconData vehicleCategoryIcon(MoveVehicleCategory category) =>
      switch (category) {
        MoveVehicleCategory.economy => Icons.directions_car_outlined,
        MoveVehicleCategory.standard => Icons.directions_car,
        MoveVehicleCategory.premium => Icons.local_taxi,
        MoveVehicleCategory.corporate => Icons.airport_shuttle,
      };

  static String driverStatus(MoveDriverStatus status) => switch (status) {
    MoveDriverStatus.none => 'Sin registro',
    MoveDriverStatus.pendingReview => 'En revisión',
    MoveDriverStatus.approved => 'Aprobado',
    MoveDriverStatus.rejected => 'Rechazado',
    MoveDriverStatus.suspended => 'Suspendido',
    MoveDriverStatus.blocked => 'Bloqueado',
  };

  static Color driverStatusColor(MoveDriverStatus status) => switch (status) {
    MoveDriverStatus.approved => Colors.green,
    MoveDriverStatus.pendingReview => Colors.amber,
    MoveDriverStatus.rejected ||
    MoveDriverStatus.suspended ||
    MoveDriverStatus.blocked => Colors.redAccent,
    MoveDriverStatus.none => Colors.grey,
  };

  /// Nombre técnico usado por el backend para filtrar historial por estado.
  static String tripStatusApiName(MoveTripStatus status) => switch (status) {
    MoveTripStatus.completed => 'Completed',
    MoveTripStatus.searching => 'Searching',
    MoveTripStatus.inProgress => 'InProgress',
    _ => status.name,
  };
}
