enum TicketEventCategory {
  movies('movies', 'Cine'),
  concerts('concerts', 'Conciertos'),
  sports('sports', 'Deportes'),
  theater('theater', 'Teatro'),
  events('events', 'Otros');

  const TicketEventCategory(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static TicketEventCategory fromApi(Object? value) {
    final raw = value?.toString().trim().toLowerCase() ?? '';
    return values.where((item) => item.apiValue == raw).firstOrNull ?? events;
  }
}

enum TicketPaymentMethod {
  ciervoBalance('CIERVO_BALANCE', 'Saldo Ciervo'),
  wallet('WALLET', 'Wallet'),
  points('POINTS', 'Puntos');

  const TicketPaymentMethod(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

class TicketEventSummary {
  const TicketEventSummary({
    required this.id,
    required this.title,
    required this.category,
    this.description,
    this.city,
    this.venue,
    this.startsAt,
    this.imageUrl,
    this.minPrice,
    this.currency,
    this.latitude,
    this.longitude,
  });

  factory TicketEventSummary.fromJson(Map<String, dynamic> json) =>
      TicketEventSummary(
        id: _string(json['id'] ?? json['eventId']),
        title: _string(json['title'] ?? json['name']),
        description: _nullableString(json['description'] ?? json['summary']),
        category: TicketEventCategory.fromApi(
          json['category'] ?? json['categoria'],
        ),
        city: _nullableString(json['city'] ?? json['ciudad']),
        venue: _nullableString(
          json['venue'] ?? json['location'] ?? json['place'],
        ),
        startsAt: _date(json['startsAt'] ?? json['date'] ?? json['fecha']),
        imageUrl: _nullableString(
          json['imageUrl'] ?? json['posterUrl'] ?? json['coverUrl'],
        ),
        minPrice: _doubleOrNull(
          json['minPrice'] ?? json['priceFrom'] ?? json['price'],
        ),
        currency: _nullableString(json['currency'] ?? json['moneda']) ?? 'COP',
        latitude: _doubleOrNull(json['latitude'] ?? json['lat']),
        longitude: _doubleOrNull(json['longitude'] ?? json['lng']),
      );

  final String id;
  final String title;
  final String? description;
  final TicketEventCategory category;
  final String? city;
  final String? venue;
  final DateTime? startsAt;
  final String? imageUrl;
  final double? minPrice;
  final String? currency;
  final double? latitude;
  final double? longitude;
}

class TicketType {
  const TicketType({
    required this.id,
    required this.name,
    required this.price,
    this.currency = 'COP',
    this.available,
    this.description,
  });

  factory TicketType.fromJson(Map<String, dynamic> json) => TicketType(
    id: _string(json['id'] ?? json['ticketTypeId']),
    name: _string(json['name'] ?? json['label'] ?? json['title']),
    description: _nullableString(json['description']),
    price: _double(json['price'] ?? json['amount']),
    currency: _nullableString(json['currency']) ?? 'COP',
    available: _intOrNull(json['available'] ?? json['stock'] ?? json['qty']),
  );

  final String id;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final int? available;
}

class TicketEventDetail {
  const TicketEventDetail({
    required this.id,
    required this.title,
    required this.category,
    this.description,
    this.city,
    this.venue,
    this.startsAt,
    this.endsAt,
    this.imageUrl,
    this.currency = 'COP',
    this.minPrice,
    this.ticketTypes = const [],
    this.hasSeatingPlan = false,
    this.latitude,
    this.longitude,
  });

  factory TicketEventDetail.fromJson(Map<String, dynamic> json) {
    final types = _maps(
      json['ticketTypes'] ?? json['types'] ?? json['ticket_types'],
    ).map(TicketType.fromJson).toList();
    final seatsHint =
        json['hasSeatingPlan'] == true ||
        json['hasSeats'] == true ||
        json['seatingPlan'] == true;
    return TicketEventDetail(
      id: _string(json['id'] ?? json['eventId']),
      title: _string(json['title'] ?? json['name']),
      description: _nullableString(json['description'] ?? json['summary']),
      category: TicketEventCategory.fromApi(
        json['category'] ?? json['categoria'],
      ),
      city: _nullableString(json['city'] ?? json['ciudad']),
      venue: _nullableString(
        json['venue'] ?? json['location'] ?? json['place'],
      ),
      startsAt: _date(json['startsAt'] ?? json['date'] ?? json['fecha']),
      endsAt: _date(json['endsAt'] ?? json['endDate']),
      imageUrl: _nullableString(
        json['imageUrl'] ?? json['posterUrl'] ?? json['coverUrl'],
      ),
      currency: _nullableString(json['currency']) ?? 'COP',
      minPrice:
          _doubleOrNull(
            json['minPrice'] ?? json['priceFrom'] ?? json['price'],
          ) ??
          (types.isEmpty ? null : types.map((t) => t.price).reduce(_min)),
      ticketTypes: types,
      hasSeatingPlan: seatsHint,
      latitude: _doubleOrNull(json['latitude'] ?? json['lat']),
      longitude: _doubleOrNull(json['longitude'] ?? json['lng']),
    );
  }

  final String id;
  final String title;
  final String? description;
  final TicketEventCategory category;
  final String? city;
  final String? venue;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? imageUrl;
  final String currency;
  final double? minPrice;
  final List<TicketType> ticketTypes;
  final bool hasSeatingPlan;
  final double? latitude;
  final double? longitude;

  TicketEventSummary toSummary() => TicketEventSummary(
    id: id,
    title: title,
    description: description,
    category: category,
    city: city,
    venue: venue,
    startsAt: startsAt,
    imageUrl: imageUrl,
    minPrice: minPrice,
    currency: currency,
    latitude: latitude,
    longitude: longitude,
  );
}

class TicketEventsPage {
  const TicketEventsPage({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });

  factory TicketEventsPage.fromJson(Map<String, dynamic> json) {
    final items = _maps(
      json['items'] ?? json['results'] ?? json['data'] ?? json['events'],
    ).map(TicketEventSummary.fromJson).toList();
    return TicketEventsPage(
      page: _int(json['page'] ?? json['pagina'], 1),
      pageSize: _int(json['pageSize'] ?? json['page_size'], 20),
      total: _int(json['total'] ?? json['totalCount'] ?? items.length),
      items: items,
    );
  }

  final int page;
  final int pageSize;
  final int total;
  final List<TicketEventSummary> items;
}

class TicketSeat {
  const TicketSeat({
    required this.id,
    required this.label,
    this.row,
    this.available = true,
    this.price,
    this.section,
  });

  factory TicketSeat.fromJson(Map<String, dynamic> json) {
    final id = _string(json['id'] ?? json['seatId'] ?? json['code']);
    return TicketSeat(
      id: id,
      label: _string(json['label'] ?? json['name'] ?? id),
      row: _nullableString(json['row'] ?? json['fila']),
      available:
          json['available'] != false &&
          json['isAvailable'] != false &&
          json['status']?.toString().toLowerCase() != 'taken' &&
          json['status']?.toString().toLowerCase() != 'occupied',
      price: _doubleOrNull(json['price']),
      section: _nullableString(json['section'] ?? json['zone']),
    );
  }

  final String id;
  final String label;
  final String? row;
  final bool available;
  final double? price;
  final String? section;
}

class SeatHold {
  const SeatHold({required this.holdId, required this.seatIds, this.expiresAt});

  factory SeatHold.fromJson(Map<String, dynamic> json) => SeatHold(
    holdId: _string(json['holdId'] ?? json['id'] ?? json['reservationId']),
    seatIds: _strings(json['seats'] ?? json['seatIds']),
    expiresAt: _date(json['expiresAt'] ?? json['holdExpiresAt']),
  );

  final String holdId;
  final List<String> seatIds;
  final DateTime? expiresAt;
}

class TicketOrder {
  const TicketOrder({
    required this.ticketId,
    required this.eventId,
    required this.status,
    this.amount,
    this.currency = 'COP',
    this.qr,
    this.seatIds = const [],
    this.eventTitle,
  });

  factory TicketOrder.fromJson(Map<String, dynamic> json) => TicketOrder(
    ticketId: _string(json['ticketId'] ?? json['id']),
    eventId: _string(json['eventId']),
    status: _string(json['status'] ?? json['state'], 'created'),
    amount: _doubleOrNull(json['amount'] ?? json['total'] ?? json['price']),
    currency: _nullableString(json['currency']) ?? 'COP',
    qr: _nullableString(json['qr'] ?? json['qrPayload'] ?? json['code']),
    seatIds: _strings(json['seatIds'] ?? json['seats']),
    eventTitle: _nullableString(json['eventTitle'] ?? json['title']),
  );

  final String ticketId;
  final String eventId;
  final String status;
  final double? amount;
  final String currency;
  final String? qr;
  final List<String> seatIds;
  final String? eventTitle;

  bool get isPaid =>
      status.toLowerCase().contains('paid') ||
      status.toLowerCase().contains('confirm') ||
      status.toLowerCase().contains('active');

  bool get canCancel =>
      !status.toLowerCase().contains('cancel') &&
      !status.toLowerCase().contains('refund') &&
      !status.toLowerCase().contains('used') &&
      !status.toLowerCase().contains('consumed');

  bool get canRefund => isPaid || status.toLowerCase().contains('paid');
}

class WalletTicket {
  const WalletTicket({
    required this.ticketId,
    required this.eventId,
    required this.title,
    required this.status,
    this.startsAt,
    this.venue,
    this.qr,
    this.amount,
    this.currency = 'COP',
    this.seatIds = const [],
    this.imageUrl,
  });

  factory WalletTicket.fromJson(Map<String, dynamic> json) => WalletTicket(
    ticketId: _string(json['ticketId'] ?? json['id']),
    eventId: _string(json['eventId']),
    title: _string(
      json['title'] ?? json['eventTitle'] ?? json['name'] ?? 'Entrada',
    ),
    status: _string(json['status'] ?? json['state'], 'active'),
    startsAt: _date(json['startsAt'] ?? json['eventDate'] ?? json['date']),
    venue: _nullableString(json['venue'] ?? json['location']),
    qr: _nullableString(json['qr'] ?? json['qrPayload'] ?? json['code']),
    amount: _doubleOrNull(json['amount'] ?? json['price'] ?? json['total']),
    currency: _nullableString(json['currency']) ?? 'COP',
    seatIds: _strings(json['seatIds'] ?? json['seats']),
    imageUrl: _nullableString(json['imageUrl'] ?? json['posterUrl']),
  );

  final String ticketId;
  final String eventId;
  final String title;
  final String status;
  final DateTime? startsAt;
  final String? venue;
  final String? qr;
  final double? amount;
  final String currency;
  final List<String> seatIds;
  final String? imageUrl;
}

class CreateTicketCommand {
  const CreateTicketCommand({
    required this.eventId,
    required this.tickets,
    required this.idempotencyKey,
    this.seatIds = const [],
    this.holdId,
    this.ticketTypeId,
  });

  final String eventId;
  final int tickets;
  final List<String> seatIds;
  final String? holdId;
  final String? ticketTypeId;
  final String idempotencyKey;

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'tickets': tickets,
    if (seatIds.isNotEmpty) 'seatIds': seatIds,
    if (holdId != null && holdId!.isNotEmpty) 'holdId': holdId,
    if (ticketTypeId != null && ticketTypeId!.isNotEmpty)
      'ticketTypeId': ticketTypeId,
    'idempotencyKey': idempotencyKey,
  };
}

class PayTicketCommand {
  const PayTicketCommand({
    required this.ticketId,
    required this.paymentMethod,
    required this.idempotencyKey,
  });

  final String ticketId;
  final TicketPaymentMethod paymentMethod;
  final String idempotencyKey;

  Map<String, dynamic> toJson() => {
    'ticketId': ticketId,
    'paymentMethod': paymentMethod.apiValue,
    'idempotencyKey': idempotencyKey,
  };
}

double _min(double a, double b) => a < b ? a : b;

String _string(Object? value, [String fallback = '']) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

int _int(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _intOrNull(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _double(Object? value, [double fallback = 0]) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

double? _doubleOrNull(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
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

List<String> _strings(Object? value) {
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  if (value is String && value.trim().isNotEmpty) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  return const [];
}
