import 'move_enums.dart';

/// Vehículo registrado por un conductor MOVE.
class MoveVehicle {
  const MoveVehicle({
    required this.id,
    required this.category,
    this.plate,
    this.brand,
    this.model,
    this.year,
    this.color,
    this.seats,
    this.status,
    this.isDefault = false,
  });

  final String id;
  final MoveVehicleCategory category;
  final String? plate;
  final String? brand;
  final String? model;
  final int? year;
  final String? color;
  final int? seats;

  /// Estado textual del backend (Active, Pending, Rejected, ...).
  final String? status;
  final bool isDefault;

  bool get isActive => (status ?? '').toLowerCase() == 'active';

  String get displayName {
    final parts = [
      if ((brand ?? '').isNotEmpty) brand,
      if ((model ?? '').isNotEmpty) model,
    ].whereType<String>().toList();
    if (parts.isEmpty) return plate ?? 'Vehículo';
    return parts.join(' ');
  }
}

/// Documento de habilitación del conductor.
class MoveDocument {
  const MoveDocument({
    required this.id,
    required this.documentType,
    this.status,
    this.documentNumber,
    this.fileUrl,
    this.expiresAt,
  });

  final String id;
  final String documentType;
  final String? status;
  final String? documentNumber;
  final String? fileUrl;
  final DateTime? expiresAt;

  bool get isApproved => (status ?? '').toLowerCase() == 'approved';
}

/// Perfil de conductor MOVE (`GET /api/v1/move/driver/me`).
class MoveDriverProfile {
  const MoveDriverProfile({
    required this.id,
    required this.status,
    this.fullName,
    this.phone,
    this.countryCode,
    this.city,
    this.rating,
    this.totalTrips,
    this.isOnline = false,
    this.vehicles = const [],
    this.documents = const [],
    this.rejectionReason,
    this.isKidsEligible = false,
  });

  final String id;
  final MoveDriverStatus status;
  final String? fullName;
  final String? phone;
  final String? countryCode;
  final String? city;
  final double? rating;
  final int? totalTrips;
  final bool isOnline;
  final List<MoveVehicle> vehicles;
  final List<MoveDocument> documents;
  final String? rejectionReason;

  /// Habilitado por el backend para viajes de menores (CIERVO MOVE Kids).
  final bool isKidsEligible;

  bool get isApproved => status.isApproved;

  bool get hasActiveVehicle => vehicles.any((v) => v.isActive);

  bool get canGoOnline => isApproved && hasActiveVehicle;
}
