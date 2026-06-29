import '../../../receipts/domain/entities/action_confirmation.dart';

class Booking {
  const Booking({
    required this.id,
    required this.publicCode,
    required this.status,
    required this.bookingType,
    required this.peopleCount,
    required this.currency,
    this.businessId,
    this.bookingDate,
    this.businessName,
    this.totalAmount,
    this.qrId,
    this.qrPayload,
    this.qrExpiresAt,
    this.confirmation,
  });

  final int id;
  final String publicCode;
  final String status;
  final String bookingType;
  final int peopleCount;
  final String currency;
  final int? businessId;
  final DateTime? bookingDate;
  final String? businessName;
  final num? totalAmount;
  final String? qrId;
  final String? qrPayload;
  final DateTime? qrExpiresAt;
  final ActionConfirmation? confirmation;
}

class EventBookingOption {
  const EventBookingOption({
    required this.id,
    required this.type,
    required this.name,
    required this.capacity,
    required this.availableQuantity,
    required this.price,
    required this.currency,
    required this.isActive,
    this.startsAt,
    this.endsAt,
  });

  final int id;
  final String type;
  final String name;
  final int capacity;
  final int availableQuantity;
  final num price;
  final String currency;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? endsAt;
}
