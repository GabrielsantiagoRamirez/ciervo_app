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

  /// Traduce claves camelCase del breakdown de tarifa a español.
  static String fareBreakdownLabel(String raw) {
    final key = raw.trim();
    if (key.isEmpty) return 'Concepto';
    final normalized = key
        .replaceAll(RegExp(r'[\s_\-]+'), '')
        .toLowerCase();
    return switch (normalized) {
      'basefare' || 'base' => 'Tarifa base',
      'distanceamount' || 'distance' || 'distancia' => 'Distancia',
      'waitamount' || 'wait' || 'waiting' || 'espera' => 'Espera',
      'tolls' || 'peajes' => 'Peajes',
      'nightsurcharge' || 'night' || 'noche' => 'Recargo nocturno',
      'rainsurcharge' || 'rain' || 'lluvia' => 'Recargo por lluvia',
      'highdemandsurcharge' || 'highdemand' || 'surge' =>
        'Recargo por alta demanda',
      'airportsurcharge' || 'airport' || 'aeropuerto' =>
        'Recargo aeropuerto',
      'promodiscount' || 'promo' || 'discount' => 'Descuento promo',
      'cashbackdiscount' || 'cashback' => 'Descuento cashback',
      'subtotal' => 'Subtotal',
      'total' || 'suggestedfare' || 'fare' => 'Total',
      'servicefee' || 'fee' => 'Cargo por servicio',
      'tax' || 'taxes' || 'iva' => 'Impuestos',
      _ => _humanizeCamelCase(key),
    };
  }

  static String _humanizeCamelCase(String value) {
    final spaced = value
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (m) => '${m[1]} ${m[2]}',
        )
        .replaceAll('_', ' ')
        .trim();
    if (spaced.isEmpty) return 'Concepto';
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}
