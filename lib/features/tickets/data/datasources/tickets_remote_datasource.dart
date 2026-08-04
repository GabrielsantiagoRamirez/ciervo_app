import '../../../../core/network/api_response_unwrapper.dart';
import '../../../../core/network/network_client.dart';
import '../../domain/models/ticket_models.dart';

abstract interface class TicketsRemoteDataSource {
  Future<TicketEventsPage> events({
    String? city,
    String? category,
    String? date,
    int page,
    int pageSize,
    double? precioMin,
    double? precioMax,
    String? organizer,
    double? latitude,
    double? longitude,
    double? radiusKm,
  });

  Future<List<TicketEventSummary>> highlights({int limit});
  Future<List<TicketEventSummary>> nearby({
    required double lat,
    required double lng,
    double radiusKm,
    int limit,
  });
  Future<List<TicketEventSummary>> recommend({
    double? lat,
    double? lng,
    int limit,
  });
  Future<TicketEventDetail> eventDetail(String eventId);
  Future<List<TicketSeat>> seats(String eventId);
  Future<SeatHold> reserveSeats(String eventId, List<String> seats);
  Future<void> releaseSeats(String eventId, String holdId);
  Future<TicketOrder> createTicket(CreateTicketCommand command);
  Future<TicketOrder> payTicket(PayTicketCommand command);
  Future<TicketOrder> refundTicket(String ticketId);
  Future<TicketOrder> cancelTicket(String ticketId);
  Future<List<WalletTicket>> walletTickets();
  Future<List<WalletTicket>> walletHistory();
  Future<WalletTicket> walletTicket(String ticketId);
}

class DioTicketsRemoteDataSource implements TicketsRemoteDataSource {
  const DioTicketsRemoteDataSource(this._client);

  final NetworkClient _client;
  static const _events = '/api/v1/events';
  static const _tickets = '/api/v1/tickets';
  static const _wallet = '/api/v1/wallet/tickets';

  @override
  Future<TicketEventsPage> events({
    String? city,
    String? category,
    String? date,
    int page = 1,
    int pageSize = 20,
    double? precioMin,
    double? precioMax,
    String? organizer,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    final response = await _client.dio.get<dynamic>(
      _events,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
        if (date != null && date.trim().isNotEmpty) 'date': date.trim(),
        if (precioMin != null) 'precioMin': precioMin,
        if (precioMax != null) 'precioMax': precioMax,
        if (organizer != null && organizer.trim().isNotEmpty)
          'organizer': organizer.trim(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (radiusKm != null) 'radiusKm': radiusKm,
      },
    );
    final value = unwrapApiResponse(response.data);
    if (value is List) {
      final items = value
          .whereType<Map>()
          .map(
            (item) =>
                TicketEventSummary.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      return TicketEventsPage(
        page: page,
        pageSize: pageSize,
        total: items.length,
        items: items,
      );
    }
    return TicketEventsPage.fromJson(_asMap(value));
  }

  @override
  Future<List<TicketEventSummary>> highlights({int limit = 20}) async {
    final response = await _client.dio.get<dynamic>(
      '$_events/highlights',
      queryParameters: {'limit': limit},
    );
    return _eventList(response.data);
  }

  @override
  Future<List<TicketEventSummary>> nearby({
    required double lat,
    required double lng,
    double radiusKm = 25,
    int limit = 20,
  }) async {
    final response = await _client.dio.get<dynamic>(
      '$_events/nearby',
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radiusKm': radiusKm,
        'limit': limit,
      },
    );
    return _eventList(response.data);
  }

  @override
  Future<List<TicketEventSummary>> recommend({
    double? lat,
    double? lng,
    int limit = 20,
  }) async {
    final response = await _client.dio.get<dynamic>(
      '/api/v1/ai/recommend-events',
      queryParameters: {
        'limit': limit,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
    );
    return _eventList(response.data);
  }

  @override
  Future<TicketEventDetail> eventDetail(String eventId) async {
    final response = await _client.dio.get<dynamic>(
      '$_events/${Uri.encodeComponent(eventId)}',
    );
    return TicketEventDetail.fromJson(_asMap(unwrapApiResponse(response.data)));
  }

  @override
  Future<List<TicketSeat>> seats(String eventId) async {
    final response = await _client.dio.get<dynamic>(
      '$_events/${Uri.encodeComponent(eventId)}/seats',
    );
    return _seatList(response.data);
  }

  @override
  Future<SeatHold> reserveSeats(String eventId, List<String> seats) async {
    final response = await _client.dio.post<dynamic>(
      '$_events/${Uri.encodeComponent(eventId)}/seats/reserve',
      data: {'seats': seats},
    );
    final value = unwrapApiResponse(response.data);
    if (value is Map<String, dynamic>) {
      return SeatHold.fromJson(value);
    }
    if (value is Map) {
      return SeatHold.fromJson(Map<String, dynamic>.from(value));
    }
    return SeatHold(holdId: value?.toString() ?? '', seatIds: seats);
  }

  @override
  Future<void> releaseSeats(String eventId, String holdId) async {
    await _client.dio.delete<dynamic>(
      '$_events/${Uri.encodeComponent(eventId)}/seats/release',
      queryParameters: {'holdId': holdId},
    );
  }

  @override
  Future<TicketOrder> createTicket(CreateTicketCommand command) async {
    final response = await _client.dio.post<dynamic>(
      '$_tickets/create',
      data: command.toJson(),
    );
    return TicketOrder.fromJson(_asMap(unwrapApiResponse(response.data)));
  }

  @override
  Future<TicketOrder> payTicket(PayTicketCommand command) async {
    final response = await _client.dio.post<dynamic>(
      '$_tickets/pay',
      data: command.toJson(),
    );
    return TicketOrder.fromJson(_asMap(unwrapApiResponse(response.data)));
  }

  @override
  Future<TicketOrder> refundTicket(String ticketId) async {
    final response = await _client.dio.post<dynamic>(
      '$_tickets/refund',
      data: {'ticketId': ticketId},
    );
    return TicketOrder.fromJson(_asMap(unwrapApiResponse(response.data)));
  }

  @override
  Future<TicketOrder> cancelTicket(String ticketId) async {
    final response = await _client.dio.post<dynamic>(
      '$_tickets/cancel',
      data: {'ticketId': ticketId},
    );
    return TicketOrder.fromJson(_asMap(unwrapApiResponse(response.data)));
  }

  @override
  Future<List<WalletTicket>> walletTickets() async {
    final response = await _client.dio.get<dynamic>(_wallet);
    return _walletList(response.data);
  }

  @override
  Future<List<WalletTicket>> walletHistory() async {
    final response = await _client.dio.get<dynamic>('$_wallet/history');
    return _walletList(response.data);
  }

  @override
  Future<WalletTicket> walletTicket(String ticketId) async {
    final response = await _client.dio.get<dynamic>(
      '$_wallet/${Uri.encodeComponent(ticketId)}',
    );
    return WalletTicket.fromJson(_asMap(unwrapApiResponse(response.data)));
  }

  List<TicketEventSummary> _eventList(Object? raw) {
    final value = unwrapApiResponse(raw);
    if (value is List) {
      return value
          .whereType<Map>()
          .map(
            (item) =>
                TicketEventSummary.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }
    final map = _asMap(value);
    return _maps(
      map['items'] ?? map['results'] ?? map['events'] ?? map['data'],
    ).map(TicketEventSummary.fromJson).toList();
  }

  List<TicketSeat> _seatList(Object? raw) {
    final value = unwrapApiResponse(raw);
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => TicketSeat.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    final map = _asMap(value);
    return _maps(
      map['seats'] ?? map['items'] ?? map['data'],
    ).map(TicketSeat.fromJson).toList();
  }

  List<WalletTicket> _walletList(Object? raw) {
    final value = unwrapApiResponse(raw);
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => WalletTicket.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    final map = _asMap(value);
    return _maps(
      map['items'] ?? map['tickets'] ?? map['data'],
    ).map(WalletTicket.fromJson).toList();
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _maps(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return const [];
}
