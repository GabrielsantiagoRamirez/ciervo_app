// ignore_for_file: unused_import

import 'package:dio/dio.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';
import '../../receipts/domain/entities/action_confirmation.dart';
import '../domain/entities/booking.dart';

class BookingRepository {
  const BookingRepository(this._client);
  final NetworkClient _client;

  Future<Result<List<Booking>>> getMine() => _guard(() async {
    final response = await _client.dio.get<dynamic>('/api/bookings/me');
    return unwrapApiList(response.data)
        .whereType<Map<String, dynamic>>()
        .map(_bookingFromJson)
        .toList();
  });

  Future<Result<Booking>> getByCode(String publicCode) => _guard(() async {
    final code = publicCode.trim().toUpperCase();
    final response = await _client.dio.get<dynamic>(
      '/api/bookings/by-code/${Uri.encodeComponent(code)}',
    );
    return _bookingFromJson(unwrapApiMap(response.data));
  });

  Future<Result<List<EventBookingOption>>> getEventOptions(int eventId) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/events/$eventId/booking-options',
        );
        return unwrapApiList(response.data)
            .whereType<Map<String, dynamic>>()
            .map(_optionFromJson)
            .where((option) => option.isActive && option.availableQuantity > 0)
            .toList();
      });

  Future<Result<Booking>> createBusinessReservation({
    required String businessId,
    required int reservableOptionId,
    required DateTime date,
    required String time,
    required int peopleCount,
    String? notes,
  }) => _guard(() async {
    final response = await _client.dio.post<dynamic>(
      '/api/businesses/$businessId/reservations',
      data: {
        'reservableOptionId': reservableOptionId,
        'date': date.toIso8601String().substring(0, 10),
        'time': _timeOnly(time),
        'peopleCount': peopleCount,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return _bookingFromJson(unwrapApiMap(response.data));
  });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}

Booking _bookingFromJson(Map<String, dynamic> json) => Booking(
  id: _int(json['id'] ?? json['reservationId']),
  publicCode:
      '${json['publicCode'] ?? json['confirmationCode'] ?? json['reference'] ?? ''}',
  status: '${json['status'] ?? 'Pending'}',
  bookingType: '${json['bookingType'] ?? json['type'] ?? 'General'}',
  peopleCount: _int(json['peopleCount']),
  currency: '${json['currency'] ?? 'COP'}',
  businessId: _intOrNull(json['businessId'] ?? json['business']?['id']),
  bookingDate: DateTime.tryParse(
    '${json['bookingDate'] ?? json['date'] ?? ''}',
  ),
  businessName: _name(json['businessName'] ?? json['business']),
  categoryName: _name(json['categoryName'] ?? json['category']),
  city: _name(json['city']),
  time: _name(json['time'] ?? json['bookingTime']),
  businessLogoUrl: _name(json['businessLogoUrl'] ?? json['logoUrl']),
  totalAmount: _num(json['totalAmount'] ?? json['amount']),
  qrId: _name(json['qrId'] ?? json['universalQrId']),
  qrPayload: _name(
    json['signedToken'] ??
        json['qrPayload'] ??
        json['qrContent'] ??
        json['token'] ??
        json['publicCode'] ??
        json['confirmationCode'],
  ),
  qrExpiresAt: DateTime.tryParse(
    '${json['qrExpiresAt'] ?? json['expiresAt'] ?? ''}',
  ),
  confirmation: ActionConfirmation.fromJson(
    json,
    fallbackTitle: 'Reserva creada',
    fallbackCode:
        '${json['publicCode'] ?? json['confirmationCode'] ?? json['reference'] ?? ''}',
  ),
);

EventBookingOption _optionFromJson(Map<String, dynamic> json) =>
    EventBookingOption(
      id: _int(json['id']),
      type: '${json['type'] ?? 'General'}',
      name: '${json['name'] ?? json['type'] ?? 'Opcion'}',
      capacity: _int(json['capacity']),
      availableQuantity: _int(json['availableQuantity']),
      price: _num(json['price']) ?? 0,
      currency: '${json['currency'] ?? 'COP'}',
      isActive: json['isActive'] != false,
      startsAt: DateTime.tryParse('${json['startsAt'] ?? ''}'),
      endsAt: DateTime.tryParse('${json['endsAt'] ?? ''}'),
    );

int _int(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;

int? _intOrNull(dynamic value) =>
    value is int ? value : int.tryParse('${value ?? ''}');

String? _name(dynamic value) {
  if (value == null) return null;
  if (value is Map) {
    return '${value['name'] ?? value['businessName'] ?? ''}';
  }
  return value.toString();
}

num? _num(dynamic value) => value is num ? value : num.tryParse('$value');

String _timeOnly(String value) {
  final trimmed = value.trim();
  final parts = trimmed.split(':');
  if (parts.length >= 3) {
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:${parts[2].padLeft(2, '0')}';
  }
  if (parts.length == 2) {
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}:00';
  }
  return trimmed;
}
